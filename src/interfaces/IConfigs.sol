// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoolId} from "../models/PoolId.sol";
import {SqrtPrice} from "../models/SqrtPrice.sol";
import {Token} from "../models/Token.sol";

/// @title IConfigs
interface IConfigs {
    /// @notice Initializes a pool's configs
    /// @param token0 The token0 address
    /// @param token1 The token1 address
    /// @param sqrtPrice The initial square root price
    /// @return rangeRatioLower The lower range ratio
    /// @return rangeRatioUpper The upper range ratio
    /// @return thresholdRatioLower The lower threshold ratio
    /// @return thresholdRatioUpper The upper threshold ratio
    /// @return minShares The minimum shares
    function initialize(Token token0, Token token1, SqrtPrice sqrtPrice)
        external
        returns (
            uint24 rangeRatioLower,
            uint24 rangeRatioUpper,
            uint32 minShares
        );
}
