// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Layout: uint128 liquidity | uint32 range ratio lower | uint32 range ratio upper | uint32 threshold ratio lower | uint32 threshold ratio upper
type Position is bytes32;

using PositionLibrary for Position global;

/// @title PositionLibrary
library PositionLibrary {
    uint32 private constant MASK_32_BITS = 0xFFFFFFFF;

    /// @notice Gets the liquidity for the position
    /// @param self The position
    /// @return _liquidity The liquidity
    function liquidity(Position self) internal pure returns (uint128 _liquidity) {
        assembly ("memory-safe") {
            _liquidity := shr(128, self)
        }
    }

    /// @notice Gets the range ratio lower for the position
    /// @param self The position
    /// @return _rangeRatioLower The range ratio lower
    function rangeRatioLower(Position self) internal pure returns (uint32 _rangeRatioLower) {
        assembly ("memory-safe") {
            _rangeRatioLower := and(shr(96, self), MASK_32_BITS)
        }
    }

    /// @notice Gets the range ratio upper for the position
    /// @param self The position
    /// @return _rangeRatioUpper The range ratio upper
    function rangeRatioUpper(Position self) internal pure returns (uint32 _rangeRatioUpper) {
        assembly ("memory-safe") {
            _rangeRatioUpper := and(shr(64, self), MASK_32_BITS)
        }
    }

    /// @notice Gets the threshold ratio lower for the position
    /// @param self The position
    /// @return _thresholdRatioLower The threshold ratio lower
    function thresholdRatioLower(Position self) internal pure returns (uint32 _thresholdRatioLower) {
        assembly ("memory-safe") {
            _thresholdRatioLower := and(shr(32, self), MASK_32_BITS)
        }
    }

    /// @notice Gets the threshold ratio upper for the position
    /// @param self The position
    /// @return _thresholdRatioUpper The threshold ratio upper
    function thresholdRatioUpper(Position self) internal pure returns (uint32 _thresholdRatioUpper) {
        assembly ("memory-safe") {
            _thresholdRatioUpper := and(self, MASK_32_BITS)
        }
    }

    /// @notice Construct a position from the given liquidity and ratios
    /// @param _liquidity The liquidity
    /// @param _rangeRatioLower The range ratio lower
    /// @param _rangeRatioUpper The range ratio upper
    /// @param _thresholdRatioLower The threshold ratio lower
    /// @param _thresholdRatioUpper The threshold ratio upper
    /// @return position The position
    function from(
        uint128 _liquidity,
        uint32 _rangeRatioLower,
        uint32 _rangeRatioUpper,
        uint32 _thresholdRatioLower,
        uint32 _thresholdRatioUpper
    ) internal pure returns (Position position) {
        assembly ("memory-safe") {
            position :=
                or(
                    shl(128, _liquidity),
                    or(
                        or(shl(96, and(_rangeRatioLower, MASK_32_BITS)), shl(64, and(_rangeRatioUpper, MASK_32_BITS))),
                        or(shl(32, and(_thresholdRatioLower, MASK_32_BITS)), and(_thresholdRatioUpper, MASK_32_BITS))
                    )
                )
        }
    }
}
