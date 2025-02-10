// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SqrtPrice} from "../models/SqrtPrice.sol";

/// @title IConfigs
interface IConfigs {
    /// @notice Gets the ratios given current square root price and reserve amounts
    /// @param sqrtPrice The current square root price
    /// @param reserve0 The reserve amount of token0
    /// @param reserve1 The reserve amount of token1
    /// @return rangeRatioLower The lower range ratio
    /// @return rangeRatioUpper The upper range ratio
    /// @return thresholdRatioLower The lower threshold ratio
    /// @return thresholdRatioUpper The upper threshold ratio
    function getRatios(SqrtPrice sqrtPrice, uint128 reserve0, uint128 reserve1)
        external
        returns (uint24 rangeRatioLower, uint24 rangeRatioUpper, uint24 thresholdRatioLower, uint24 thresholdRatioUpper);
}
