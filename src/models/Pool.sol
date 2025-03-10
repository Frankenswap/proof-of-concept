// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {IShareToken} from "../interfaces/IShareToken.sol";
import {IConfigs} from "../interfaces/IConfigs.sol";
import {FullMath} from "../library/FullMath.sol";
import {LiquidityMath} from "../library/LiquidityMath.sol";
import {SafeCast} from "../library/SafeCast.sol";
import {ShareToken} from "../ShareToken.sol";
import {BalanceDelta, toBalanceDelta} from "./BalanceDelta.sol";
import {PoolId} from "./PoolId.sol";
import {PoolKey} from "./PoolKey.sol";
import {SqrtPrice} from "./SqrtPrice.sol";
import {OrderId} from "./OrderId.sol";
import {OrderLevel, OrderLevelLibrary} from "./OrderLevel.sol";
import {SwapFlag, SwapFlagLibrary} from "./SwapFlag.sol";

import {console} from "forge-std/console.sol";

struct Pool {
    uint128 reserve0;
    uint128 reserve1;
    IShareToken shareToken;
    SqrtPrice sqrtPrice;
    SqrtPrice lastRebalanceSqrtPrice;
    uint24 rangeRatioLower;
    uint24 rangeRatioUpper;
    uint24 thresholdRatioLower;
    uint24 thresholdRatioUpper;
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

    using SafeCast for uint256;
    using SafeCast for int256;
    using OrderLevelLibrary for mapping(SqrtPrice => OrderLevel);

    function initialize(
        Pool storage self,
        PoolKey calldata poolKey,
        SqrtPrice sqrtPrice,
        uint128 amount0Desired,
        uint128 amount1Desired
    ) internal returns (IShareToken shareToken, uint128 shares, BalanceDelta balanceDelta) {
        require(!self.isInitialized(), PoolAlreadyInitialized());
        require(SqrtPrice.unwrap(sqrtPrice) != 0, SqrtPriceCannotBeZero());

        (
            uint24 rangeRatioLower,
            uint24 rangeRatioUpper,
            uint24 thresholdRatioLower,
            uint24 thresholdRatioUpper,
            uint32 minShares
        ) = poolKey.configs.initialize(poolKey.token0, poolKey.token1, sqrtPrice);
        // TODO: validate returned values

        shareToken = new ShareToken{salt: PoolId.unwrap(poolKey.toId())}();

        // TODO: hardcoding 1e6 for now
        SqrtPrice sqrtPriceLower =
            SqrtPrice.wrap(FullMath.mulDiv(SqrtPrice.unwrap(sqrtPrice), rangeRatioLower, 1e6).toUint160());
        console.log("sqrtPriceLower: ", SqrtPrice.unwrap(sqrtPriceLower));

        SqrtPrice sqrtPriceUpper =
            SqrtPrice.wrap(FullMath.mulDiv(SqrtPrice.unwrap(sqrtPrice), rangeRatioUpper, 1e6).toUint160());
        console.log("sqrtPriceUpper: ", SqrtPrice.unwrap(sqrtPriceUpper));

        uint128 liquidityLower = LiquidityMath.getLiquidityLower(sqrtPrice, sqrtPriceLower, amount1Desired);
        console.log("liquidityLower: ", liquidityLower);

        uint128 liquidityUpper = LiquidityMath.getLiquidityUpper(sqrtPrice, sqrtPriceUpper, amount0Desired);
        console.log("liquidityUpper: ", liquidityUpper);

        shares = liquidityLower > liquidityUpper ? liquidityUpper : liquidityLower;
        console.log("shares: ", shares);

        uint256 amount0 = LiquidityMath.getAmount0(sqrtPrice, sqrtPriceUpper, shares, true);
        console.log("amount0: ", amount0);
        uint256 amount1 = LiquidityMath.getAmount1(sqrtPriceLower, sqrtPrice, shares, true);
        console.log("amount1: ", amount1);

        balanceDelta = toBalanceDelta(-amount0.uint256toInt128(), -amount1.uint256toInt128());

        self.reserve0 = amount0.toUint128();
        self.reserve1 = amount1.toUint128();
        self.shareToken = shareToken;
        self.sqrtPrice = sqrtPrice;
        self.rangeRatioLower = rangeRatioLower;
        self.rangeRatioUpper = rangeRatioUpper;
        self.thresholdRatioLower = thresholdRatioLower;
        self.thresholdRatioUpper = thresholdRatioUpper;
        self.bestAsk = SqrtPrice.wrap(0);
        self.bestBid = SqrtPrice.wrap(type(uint160).max);
        self.orderLevels.initialize();

        shareToken.mint(address(0), minShares);
        shareToken.mint(msg.sender, shares - minShares);
    }

    function rebalance(Pool storage self, SqrtPrice sqrtPrice, PoolKey calldata poolKey)
        internal
        returns (uint24 rangeRatioLower, uint24 rangeRatioUpper, uint24 thresholdRatioLower, uint24 thresholdRatioUpper)
    {
        (rangeRatioLower, rangeRatioUpper, thresholdRatioLower, thresholdRatioUpper) =
            poolKey.configs.rebalance(poolKey.token0, poolKey.token1, sqrtPrice);

        self.rangeRatioLower = rangeRatioLower;
        self.rangeRatioUpper = rangeRatioUpper;
        self.thresholdRatioLower = thresholdRatioLower;
        self.thresholdRatioUpper = thresholdRatioUpper;
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
        SqrtPrice lastRebalanceSqrtPrice;
        SqrtPrice rangeRatioPrice;
        SqrtPrice thresholdRatioPrice;
        uint128 liquidity;
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
        PoolKey calldata poolKey,
        PlaceOrderParams memory params
    ) internal returns (OrderId orderId, BalanceDelta balanceDelta) {
        StepComputations memory step;

        step.sqrtPrice = self.sqrtPrice;
        step.lastRebalanceSqrtPrice = self.lastRebalanceSqrtPrice;
        step.reserve0 = self.reserve0;
        step.reserve1 = self.reserve1;

        int256 amountSpecifiedRemaining = params.amountSpecified;
        int256 amountCalculated = 0;

        // zeroForOne -> Price Down -> targetTick / bestBid / thresholdRatioLower
        if (params.zeroForOne) {
            step.bestPrice = self.bestBid;
            if (step.sqrtPrice < params.targetTick) {
                (orderId, balanceDelta) = self.orderLevels.placeOrder(params);
                // TODO: update order best ask
                // TODO: partially fillable
            } else {
                step.thresholdRatioPrice = SqrtPrice.wrap(
                    FullMath.mulDiv(SqrtPrice.unwrap(step.lastRebalanceSqrtPrice), self.thresholdRatioLower, 1e6)
                        .toUint160()
                );

                step.rangeRatioPrice = SqrtPrice.wrap(
                    FullMath.mulDiv(SqrtPrice.unwrap(step.lastRebalanceSqrtPrice), self.rangeRatioLower, 1e6).toUint160(
                    )
                );

                // TODO: While loop to swap

                // next price and flag
                (SqrtPrice targetPrice, SwapFlag flag) = SwapFlagLibrary.toFlag(
                    step.bestPrice, params.targetTick, step.thresholdRatioPrice, params.zeroForOne
                );

                // Liquidity
                step.liquidity = LiquidityMath.getLiquidityLower(step.sqrtPrice, step.rangeRatioPrice, self.reserve1);

                // Compute Swap
                (step.sqrtPrice, step.amountIn, step.amountOut) =
                    LiquidityMath.computeSwap(step.sqrtPrice, targetPrice, step.liquidity, amountSpecifiedRemaining);

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
                        BalanceDelta delta;
                        bool isUpdated;
                        // TODO: Int256
                        (amountSpecifiedRemaining, sqrtPriceNext, delta, isUpdated) = self.orderLevels.fillOrder(
                            params.zeroForOne, targetPrice, amountSpecifiedRemaining.toInt128()
                        );

                        // Why not use amountSpecifiedRemaining? amountSpecifiedRemaining == orderlevel.totalOpenAmount
                        if (isUpdated) {
                            step.bestPrice = sqrtPriceNext;
                        }

                        balanceDelta = balanceDelta + delta;
                    }

                    // If RebalanceFlag, rebalance
                    if (flag.isRebalanceFlag()) {
                        (uint24 rangeRatioLower,, uint24 thresholdRatioLower,) = self.rebalance(step.sqrtPrice, poolKey);
                        step.lastRebalanceSqrtPrice = step.sqrtPrice;
                        step.thresholdRatioPrice = SqrtPrice.wrap(
                            FullMath.mulDiv(SqrtPrice.unwrap(step.lastRebalanceSqrtPrice), thresholdRatioLower, 1e6)
                                .toUint160()
                        );

                        step.rangeRatioPrice = SqrtPrice.wrap(
                            FullMath.mulDiv(SqrtPrice.unwrap(step.lastRebalanceSqrtPrice), rangeRatioLower, 1e6)
                                .toUint160()
                        );
                    }

                    // If AddOrderFlag, add order
                    if (flag.isAddOrderFlag()) {
                        if (partiallyFillable && goodTillCancelled) {
                            params.amountSpecified = amountSpecifiedRemaining.toInt128();
                            params.currentTick = step.sqrtPrice;

                            (orderId, balanceDelta) = self.orderLevels.placeOrder(params);
                        }
                    }
                }
            }
        } else {}
    }

    function isInitialized(Pool storage self) internal view returns (bool) {
        return SqrtPrice.unwrap(self.sqrtPrice) != 0 && address(self.shareToken) != address(0);
    }
}
