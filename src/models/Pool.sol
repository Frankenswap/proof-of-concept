// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {IConfigs} from "../interfaces/IConfigs.sol";
import {IShareToken} from "../interfaces/IShareToken.sol";
import {SqrtPrice} from "./SqrtPrice.sol";
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

using PoolLibrary for Pool global;

/// @title PoolLibrary
library PoolLibrary {
    /// @notice Thrown when the pool is already initialized
    error PoolAlreadyInitialized();

    /// @notice Thrown when the square root price is zero
    error SqrtPriceCannotBeZero();

    using OrderLevelLibrary for mapping(SqrtPrice => OrderLevel);

    /// @notice Initialize the pool
    /// @param self The pool
    /// @param shareToken The share token contract
    /// @param sqrtPrice The initial square root price
    /// @param configs The configs contract
    function initialize(Pool storage self, IShareToken shareToken, SqrtPrice sqrtPrice, IConfigs configs)
        internal
        returns (uint24 rangeRatioLower, uint24 rangeRatioUpper, uint24 thresholdRatioLower, uint24 thresholdRatioUpper)
    {
        require(!self.isInitialized(), PoolAlreadyInitialized());
        require(SqrtPrice.unwrap(sqrtPrice) != 0, SqrtPriceCannotBeZero());

        (rangeRatioLower, rangeRatioUpper, thresholdRatioLower, thresholdRatioUpper) =
            configs.getRatios(sqrtPrice, 0, 0);

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

    // TODO: all other functions needs to check that pool is initialized

    function isInitialized(Pool storage self) internal view returns (bool) {
        return SqrtPrice.unwrap(self.sqrtPrice) != 0 && address(self.shareToken) != address(0);
    }
}
