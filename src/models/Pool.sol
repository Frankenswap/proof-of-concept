// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {IShareToken} from "../interfaces/IShareToken.sol";
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

struct Pool {
    uint128 reserve0;
    uint128 reserve1;
    IShareToken shareToken;
    SqrtPrice sqrtPrice;
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
    /// @notice Thrown when the pool is already initialized
    error PoolAlreadyInitialized();

    /// @notice Thrown when the pool is not initialized
    error PoolNotInitialized();

    /// @notice Thrown when the square root price is zero
    error SqrtPriceCannotBeZero();

    using SafeCast for uint256;
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
        SqrtPrice sqrtPriceUpper =
            SqrtPrice.wrap(FullMath.mulDiv(SqrtPrice.unwrap(sqrtPrice), rangeRatioUpper, 1e6).toUint160());

        uint128 liquidityLower = LiquidityMath.getLiquidityLower(sqrtPrice, sqrtPriceLower, amount1Desired);
        uint128 liquidityUpper = LiquidityMath.getLiquidityUpper(sqrtPrice, sqrtPriceUpper, amount0Desired);
        shares = liquidityLower > liquidityUpper ? liquidityUpper : liquidityLower;

        uint256 amount0 = LiquidityMath.getAmount0(sqrtPrice, sqrtPriceUpper, shares, true);
        uint256 amount1 = LiquidityMath.getAmount1(sqrtPriceLower, sqrtPrice, shares, true);
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

    struct PlaceOrderParams {
        address maker;
        bool zeroForOne;
        int128 amountSpecified;
        SqrtPrice targetTick;
        SqrtPrice currentTick;
        SqrtPrice[] neighborTicks;
    }

    function placeOrder(
        Pool storage self,
        bool partiallyFillable,
        bool goodTillCancelled,
        PlaceOrderParams memory params
    ) internal returns (OrderId orderId, BalanceDelta balanceDelta) {}

    function isInitialized(Pool storage self) internal view returns (bool) {
        return SqrtPrice.unwrap(self.sqrtPrice) != 0 && address(self.shareToken) != address(0);
    }
}
