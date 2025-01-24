// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Reserve} from "../models/Reserve.sol";
import {SqrtPrice} from "../models/SqrtPrice.sol";

/// @title IConfigs
interface IConfigs {
    /// @notice Gets the position ratios given current square root price and reserve amounts
    /// @param sqrtPrice The current square root price
    /// @param reserve The current reserve amounts
    /// @return rangeRatioLower The lower range ratio
    /// @return rangeRatioUpper The upper range ratio
    /// @return thresholdRatioLower The lower threshold ratio
    /// @return thresholdRatioUpper The upper threshold ratio
    function getPositionRatios(SqrtPrice sqrtPrice, Reserve reserve)
        external
        returns (uint32 rangeRatioLower, uint32 rangeRatioUpper, uint32 thresholdRatioLower, uint32 thresholdRatioUpper);
}
