// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {IConfigs} from "../interfaces/IConfigs.sol";
import {IShareToken} from "../interfaces/IShareToken.sol";
import {SafeCast} from "../library/SafeCast.sol";
import {FullMath} from "../library/FullMath.sol";
import {BalanceDelta, toBalanceDelta} from "./BalanceDelta.sol";
import {SqrtPrice, SqrtPriceLibrary} from "./SqrtPrice.sol";
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

    // /// @notice Initialize the pool
    // /// @param self The pool
    // /// @param shareToken The share token contract
    // /// @param sqrtPrice The initial square root price
    // /// @param configs The configs contract
    // function initialize(
    //     Pool storage self,
    //     IShareToken shareToken,
    //     SqrtPrice sqrtPrice,
    //     IConfigs configs,
    //     uint128 liquidity
    // ) internal returns (BalanceDelta balanceDelta) {

    //     int128 amount0 = SqrtPriceLibrary.getAmount0(sqrtPrice, sqrtPriceUpper, liquidity, true).uint256toInt128();
    //     int128 amount1 = SqrtPriceLibrary.getAmount1(sqrtPriceLower, sqrtPrice, liquidity, true).uint256toInt128();

    //
    // }

    function initialize(
        Pool storage self,
        IConfigs configs,
        IShareToken shareToken,
        SqrtPrice sqrtPrice,
        uint128 amount0Desired,
        uint128 amount1Desired
    ) internal returns (uint128 shares, BalanceDelta balanceDelta) {
        require(!self.isInitialized(), PoolAlreadyInitialized());
        require(SqrtPrice.unwrap(sqrtPrice) != 0, SqrtPriceCannotBeZero());

        (uint24 rangeRatioLower, uint24 rangeRatioUpper, uint24 thresholdRatioLower, uint24 thresholdRatioUpper) =
            configs.getRatios(sqrtPrice, 0, 0);
        // TODO: need to validate ratio values
        // TODO: get MIN_LIQUIDITY from configs

        // TODO: not safe, neet to check for overflow
        // TODO: hardcoded 1e6 for now, move to somewhere else
        uint256 sqrtPriceLower = FullMath.mulDiv(SqrtPrice.unwrap(sqrtPrice), rangeRatioLower, 1e6);
        uint256 sqrtPriceUpper = FullMath.mulDiv(SqrtPrice.unwrap(sqrtPrice), rangeRatioUpper, 1e6);

        // TODO: wait for liquidity library
        uint128 liquidityLower;
        uint128 liquidityUpper;

        // TODO: wait for liquidity library
        uint128 amount0;
        uint128 amount1;
        if (liquidityLower > liquidityUpper) {
            shares = liquidityUpper;
        } else {
            shares = liquidityLower;
        }

        balanceDelta = toBalanceDelta(-amount0.toInt128(), -amount1.toInt128());

        self.reserve0 = amount0;
        self.reserve1 = amount1;
        self.shareToken = shareToken;
        self.sqrtPrice = sqrtPrice;
        self.rangeRatioLower = rangeRatioLower;
        self.rangeRatioUpper = rangeRatioUpper;
        self.thresholdRatioLower = thresholdRatioLower;
        self.thresholdRatioUpper = thresholdRatioUpper;
        self.bestAsk = SqrtPrice.wrap(0);
        self.bestBid = SqrtPrice.wrap(type(uint160).max);
        self.orderLevels.initialize();
    }

    function modifyReserves(Pool storage self, int128 sharesDelta) internal returns (BalanceDelta balanceDelta) {
        require(self.isInitialized(), PoolNotInitialized());

        uint256 totalShares = self.shareToken.totalSupply();

        if (sharesDelta > 0) {
            uint256 amount0 = FullMath.mulDivUp(self.reserve0, uint128(sharesDelta), totalShares);
            uint256 amount1 = FullMath.mulDivUp(self.reserve1, uint128(sharesDelta), totalShares);

            self.reserve0 += uint128(amount0.uint256toInt128());
            self.reserve1 += uint128(amount1.uint256toInt128());
            balanceDelta = toBalanceDelta(-amount0.uint256toInt128(), -amount1.uint256toInt128());
        } else {
            uint256 amount0 = FullMath.mulDiv(self.reserve0, uint128(-sharesDelta), totalShares);
            uint256 amount1 = FullMath.mulDiv(self.reserve1, uint128(-sharesDelta), totalShares);

            self.reserve0 -= uint128(amount0.uint256toInt128());
            self.reserve1 -= uint128(amount1.uint256toInt128());
            balanceDelta = toBalanceDelta(amount0.uint256toInt128(), amount1.uint256toInt128());
        }
    }

    // TODO: all other functions needs to check that pool is initialized

    function isInitialized(Pool storage self) internal view returns (bool) {
        return SqrtPrice.unwrap(self.sqrtPrice) != 0 && address(self.shareToken) != address(0);
    }
}
