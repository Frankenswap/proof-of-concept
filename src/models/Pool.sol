// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {IConfigs} from "../interfaces/IConfigs.sol";
import {IShareToken} from "../interfaces/IShareToken.sol";
import {Position, PositionLibrary} from "./Position.sol";
import {Reserve} from "./Reserve.sol";
import {SqrtPrice} from "./SqrtPrice.sol";
import {OrderLevel, OrderLevelLibrary} from "./OrderLevel.sol";

struct Pool {
    Reserve reserve;
    IShareToken shareToken;
    SqrtPrice sqrtPrice;
    Position position;
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
        returns (Position position)
    {
        require(!self.isInitialized(), PoolAlreadyInitialized());
        require(SqrtPrice.unwrap(sqrtPrice) != 0, SqrtPriceCannotBeZero());

        (uint32 rangeRatioLower, uint32 rangeRatioUpper, uint32 thresholdRatioLower, uint32 thresholdRatioUpper) =
            configs.getPositionRatios(sqrtPrice, Reserve.wrap(0));
        position = PositionLibrary.from(0, rangeRatioLower, rangeRatioUpper, thresholdRatioLower, thresholdRatioUpper);

        self.shareToken = shareToken;
        self.sqrtPrice = sqrtPrice;
        self.position = position;
        self.bestAsk = SqrtPrice.wrap(0);
        self.bestBid = SqrtPrice.wrap(type(uint160).max);
        self.orderLevels.initialize();
    }

    // TODO: all other functions needs to check that pool is initialized

    function isInitialized(Pool storage self) internal view returns (bool) {
        return SqrtPrice.unwrap(self.sqrtPrice) != 0 && address(self.shareToken) != address(0);
    }
}
