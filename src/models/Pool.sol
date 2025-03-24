// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {IShareToken} from "../interfaces/IShareToken.sol";
import {IConfigs} from "../interfaces/IConfigs.sol";
import {FullMath} from "../libraries/FullMath.sol";
import {LiquidityMath} from "../libraries/LiquidityMath.sol";
import {SafeCast} from "../libraries/SafeCast.sol";
import {ShareToken} from "../ShareToken.sol";
import {BalanceDelta, toBalanceDelta} from "./BalanceDelta.sol";
import {PoolId} from "./PoolId.sol";
import {PoolKey} from "./PoolKey.sol";
import {SqrtPrice} from "./SqrtPrice.sol";
import {OrderId} from "./OrderId.sol";
import {OrderLevel, OrderLevelLibrary} from "./OrderLevel.sol";
import {SwapFlag, SwapFlagLibrary} from "./SwapFlag.sol";

struct Pool {
    uint128 reserve0;
    uint128 reserve1;
    IShareToken shareToken;
    SqrtPrice sqrtPrice;
    uint24 rangeRatioLower;
    uint24 rangeRatioUpper;
    SqrtPrice bestAsk;
    SqrtPrice bestBid;
    mapping(SqrtPrice => OrderLevel) orderLevels;
}

using SafeCast for uint128;
using SafeCast for uint256;
using PoolLibrary for Pool global;

/// @title PoolLibrary
library PoolLibrary {
    using OrderLevelLibrary for mapping(SqrtPrice => OrderLevel);

    /// @notice Thrown when the pool is already initialized
    error PoolAlreadyInitialized();

    /// @notice Thrown when the pool is not initialized
    error PoolNotInitialized();

    /// @notice Thrown when the square root price is zero
    error SqrtPriceCannotBeZero();

    /// @notice Thrown when not place order
    error MustPlaceOrder();

    using SafeCast for uint256;
    using SafeCast for int256;
    using OrderLevelLibrary for mapping(SqrtPrice => OrderLevel);

    function initialize(
        Pool storage self,
        PoolKey memory poolKey, // TODO: calldata
        SqrtPrice sqrtPrice,
        uint128 shares
    ) internal returns (IShareToken shareToken, BalanceDelta balanceDelta) {
        require(!self.isInitialized(), PoolAlreadyInitialized());
        require(SqrtPrice.unwrap(sqrtPrice) != 0, SqrtPriceCannotBeZero());

        (uint24 rangeRatioLower, uint24 rangeRatioUpper, uint32 minShares) =
            poolKey.configs.initialize(poolKey.token0, poolKey.token1, sqrtPrice);
        // TODO: validate returned values

        shareToken = new ShareToken{salt: PoolId.unwrap(poolKey.memToId())}();

        // TODO: hardcoding 1e6 for now
        SqrtPrice sqrtPriceLower =
            SqrtPrice.wrap(FullMath.mulDiv(SqrtPrice.unwrap(sqrtPrice), rangeRatioLower, 1e6).toUint160());

        SqrtPrice sqrtPriceUpper =
            SqrtPrice.wrap(FullMath.mulDiv(SqrtPrice.unwrap(sqrtPrice), rangeRatioUpper, 1e6).toUint160());

        uint256 amount0 = LiquidityMath.getAmount0(sqrtPrice, sqrtPriceUpper, shares, true);
        uint256 amount1 = LiquidityMath.getAmount1(sqrtPriceLower, sqrtPrice, shares, true);

        balanceDelta = toBalanceDelta(-amount0.uint256toInt128(), -amount1.uint256toInt128());

        self.reserve0 = amount0.toUint128();
        self.reserve1 = amount1.toUint128();
        self.shareToken = shareToken;
        self.sqrtPrice = sqrtPrice;
        self.rangeRatioLower = rangeRatioLower;
        self.rangeRatioUpper = rangeRatioUpper;
        // ask > bid
        self.bestAsk = SqrtPrice.wrap(type(uint160).max);
        self.bestBid = SqrtPrice.wrap(0);
        self.orderLevels.initialize();

        shareToken.mint(address(0), minShares);
        shareToken.mint(msg.sender, shares - minShares);
    }

    function modifyReserves(Pool storage self, int128 sharesDelta) internal returns (BalanceDelta balanceDelta) {
        require(self.isInitialized(), PoolNotInitialized());

        uint256 totalShares = self.shareToken.totalSupply();

        if (sharesDelta > 0) {
            uint256 amount0 = FullMath.mulDivUp(self.reserve0, uint128(sharesDelta), totalShares);
            uint256 amount1 = FullMath.mulDivUp(self.reserve1, uint128(sharesDelta), totalShares);

            self.reserve0 += amount0.toUint128();
            self.reserve1 += amount1.toUint128();
            balanceDelta = toBalanceDelta(-amount0.uint256toInt128(), -amount1.uint256toInt128());

            self.shareToken.mint(msg.sender, uint128(sharesDelta));
        } else {
            uint256 amount0 = FullMath.mulDiv(self.reserve0, uint128(-sharesDelta), totalShares);
            uint256 amount1 = FullMath.mulDiv(self.reserve1, uint128(-sharesDelta), totalShares);

            self.reserve0 -= uint128(amount0.uint256toInt128());
            self.reserve1 -= uint128(amount1.uint256toInt128());
            balanceDelta = toBalanceDelta(amount0.uint256toInt128(), amount1.uint256toInt128());

            self.shareToken.burn(msg.sender, uint128(-sharesDelta));
        }
    }

    // TODO: all other functions needs to check that pool is initialized

    struct StepComputations {
        SqrtPrice sqrtPrice;
        SqrtPrice bestPrice;
        SqrtPrice rangeRatioPrice;
        uint256 amountIn;
        uint256 amountOut;
        uint128 reserve0;
        uint128 reserve1;
    }

    // liquidity + rebalance price + last sqrt price

    struct PlaceOrderParams {
        address maker;
        bool zeroForOne;
        int128 amountSpecified;
        SqrtPrice targetTick;
        SqrtPrice currentTick;
        SqrtPrice[] neighborTicks;
    }

    // TODO: Fee
    function placeOrder(
        Pool storage self,
        bool partiallyFillable,
        bool goodTillCancelled,
        PlaceOrderParams memory params
    ) internal returns (OrderId orderId, BalanceDelta balanceDelta) {
        StepComputations memory step;
        bool zeroForOne = params.zeroForOne;

        step.sqrtPrice = self.sqrtPrice;
        step.reserve0 = self.reserve0;
        step.reserve1 = self.reserve1;

        int256 amountSpecifiedRemaining = params.amountSpecified;
        int256 amountCalculated = 0;

        int256 orderSpecifiedRemaining = 0;
        int256 orderAmountCalculated = 0;

        // Liquidity
        SqrtPrice sqrtPriceLower =
            SqrtPrice.wrap(FullMath.mulDiv(SqrtPrice.unwrap(step.sqrtPrice), self.rangeRatioLower, 1e6).toUint160());
        SqrtPrice sqrtPriceUpper =
            SqrtPrice.wrap(FullMath.mulDiv(SqrtPrice.unwrap(step.sqrtPrice), self.rangeRatioUpper, 1e6).toUint160());
        uint128 liquidityLower = LiquidityMath.getLiquidityLower(step.sqrtPrice, sqrtPriceLower, step.reserve1);
        uint128 liquidityUpper = LiquidityMath.getLiquidityUpper(step.sqrtPrice, sqrtPriceUpper, step.reserve0);

        uint128 liquidity = liquidityLower > liquidityUpper ? liquidityUpper : liquidityLower;

        // zeroForOne -> Price Down -> targetTick / bestBid
        // read best price
        step.bestPrice = zeroForOne ? self.bestBid : self.bestAsk;

        if (zeroForOne == (step.sqrtPrice < params.targetTick) && step.sqrtPrice != params.targetTick) {
            // partially fillable
            if (goodTillCancelled) {
                uint256 orderAmount;
                (orderId, step.amountIn, orderAmount) = self.orderLevels.placeOrder(params);
                // update order best ask
                if (zeroForOne) {
                    if (params.targetTick < self.bestAsk) {
                        step.bestPrice = params.targetTick;
                    }
                } else {
                    if (params.targetTick > self.bestBid) {
                        step.bestPrice = params.targetTick;
                    }
                }

                if (params.amountSpecified >= 0) {
                    orderSpecifiedRemaining += orderAmount.toInt256();
                    orderAmountCalculated -= step.amountIn.toInt256();
                }

                amountSpecifiedRemaining = 0;
            } else {
                // TODO: Revert Err
                revert MustPlaceOrder();
            }
        } else {
            do {
                // next price and flag
                (SqrtPrice targetPrice, SwapFlag flag) =
                    SwapFlagLibrary.toFlag(step.bestPrice, params.targetTick, zeroForOne);

                // Compute Swap
                (step.sqrtPrice, step.amountIn, step.amountOut) =
                    LiquidityMath.computeSwap(step.sqrtPrice, targetPrice, liquidity, amountSpecifiedRemaining);

                unchecked {
                    if (params.amountSpecified > 0) {
                        amountSpecifiedRemaining -= step.amountOut.toInt256();
                        amountCalculated -= step.amountIn.toInt256();
                    } else {
                        amountSpecifiedRemaining += step.amountIn.toInt256();
                        amountCalculated += step.amountOut.toInt256();
                    }

                    step.reserve0 += step.amountIn.toUint128();
                    step.reserve1 -= step.amountOut.toUint128();
                }

                if (step.sqrtPrice == targetPrice) {
                    // Fill order in orderLevel
                    if (flag.isFilOrderFlag()) {
                        SqrtPrice sqrtPriceNext;
                        bool isUpdated;

                        // TODO: Int256
                        (sqrtPriceNext, step.amountIn, step.amountOut, isUpdated) =
                            self.orderLevels.fillOrder(zeroForOne, targetPrice, amountSpecifiedRemaining);

                        // Why not use amountSpecifiedRemaining? amountSpecifiedRemaining == orderlevel.totalOpenAmount
                        if (isUpdated) {
                            step.bestPrice = sqrtPriceNext;
                        }

                        unchecked {
                            if (params.amountSpecified > 0) {
                                amountSpecifiedRemaining -= step.amountOut.toInt256();
                                amountCalculated -= step.amountIn.toInt256();
                            } else {
                                amountSpecifiedRemaining += step.amountIn.toInt256();
                                amountCalculated += step.amountOut.toInt256();
                            }
                        }
                    }

                    if (amountSpecifiedRemaining != 0) {
                        // If AddOrderFlag, add order
                        if (flag.isAddOrderFlag()) {
                            if (partiallyFillable && goodTillCancelled) {
                                params.amountSpecified = amountSpecifiedRemaining.toInt128();
                                params.currentTick = step.sqrtPrice;

                                uint256 orderAmount;
                                (orderId, step.amountIn, orderAmount) = self.orderLevels.placeOrder(params);

                                if (params.amountSpecified >= 0) {
                                    orderSpecifiedRemaining += orderAmount.toInt256();
                                    orderAmountCalculated -= step.amountIn.toInt256();
                                }

                                amountSpecifiedRemaining = 0;
                                step.bestPrice = step.sqrtPrice;
                            }
                        }
                    }
                }
            } while (!(amountSpecifiedRemaining == 0 || step.sqrtPrice == params.targetTick));
        }

        if (self.reserve0 != step.reserve0) {
            self.reserve0 = step.reserve0;
            self.reserve1 = step.reserve1;
            self.sqrtPrice = step.sqrtPrice;
        }
        // bestPrice write
        if (zeroForOne) {
            if (self.bestAsk != step.bestPrice) {
                self.bestAsk = step.bestPrice;
            }
        } else {
            if (self.bestBid != step.bestPrice) {
                self.bestBid = step.bestPrice;
            }
        }

        // "if currency1 is specified"
        if (zeroForOne != (params.amountSpecified < 0)) {
            balanceDelta = toBalanceDelta(
                (amountCalculated + orderAmountCalculated).toInt128(),
                (params.amountSpecified - amountSpecifiedRemaining - orderSpecifiedRemaining).toInt128()
            );
        } else {
            balanceDelta = toBalanceDelta(
                (params.amountSpecified - amountSpecifiedRemaining - orderSpecifiedRemaining).toInt128(),
                (amountCalculated + orderAmountCalculated).toInt128()
            );
        }
    }

    function removeOrder(Pool storage self, OrderId orderId)
        internal
        returns (address orderMaker, BalanceDelta balanceDelta)
    {
        (orderMaker, balanceDelta) = self.orderLevels.removeOrder(orderId);
    }

    function isInitialized(Pool storage self) internal view returns (bool) {
        return SqrtPrice.unwrap(self.sqrtPrice) != 0 && address(self.shareToken) != address(0);
    }
}
