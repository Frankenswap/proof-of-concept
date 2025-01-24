// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Layout: uint128 liquidity | uint32 range ratio lower | uint32 range ratio upper | uint32 threshold ratio lower | uint32 threshold ratio upper
type Position is bytes32;

using PositionLibrary for Position global;

/// @title PositionLibrary
library PositionLibrary {
    uint32 private constant UNIT_RATIO = 1_000_000;
    uint64 private constant MASK_32_BITS = 0xFFFFFFFF;

    /// @notice Sets the liquidity and ratios for the position
    /// @param self The position
    /// @param liquidity The liquidity
    /// @param rangeRatioLower The range ratio lower
    /// @param rangeRatioUpper The range ratio upper
    /// @param thresholdRatioLower The threshold ratio lower
    /// @param thresholdRatioUpper The threshold ratio upper
    function setLiquidityAndRatios(
        Position self,
        uint128 liquidity,
        uint32 rangeRatioLower,
        uint32 rangeRatioUpper,
        uint32 thresholdRatioLower,
        uint32 thresholdRatioUpper
    ) internal pure {
        // TODO: validate ratios (rangeRatioLower < thresholdRatioLower < 1, 1 < thresholdRatioUpper < rangeRatioUpper)

        assembly ("memory-safe") {
            self :=
                or(
                    shl(128, liquidity),
                    or(
                        or(shl(96, and(rangeRatioLower, MASK_32_BITS)), shl(64, and(rangeRatioUpper, MASK_32_BITS))),
                        or(shl(32, and(thresholdRatioLower, MASK_32_BITS)), and(thresholdRatioUpper, MASK_32_BITS))
                    )
                )
        }
    }
}
