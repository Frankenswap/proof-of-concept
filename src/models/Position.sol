// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Layout: uint128 liquidity | 32 empty | uint24 rangeRatioLower | uint24 rangeRatioUpper | uint24 thresholdRatioLower | uint24 thresholdRatioUpper
type Position is bytes32;

using PositionLibrary for Position global;

/// @title PositionLibrary
library PositionLibrary {
    uint24 private constant MASK_24_BITS = 0xFFFFFF;

    function liquidity(Position self) internal pure returns (uint128 _liquidity) {
        assembly ("memory-safe") {
            _liquidity := shr(128, self)
        }
    }

    function rangeRatioLower(Position self) internal pure returns (uint24 _rangeRatioLower) {
        assembly ("memory-safe") {
            _rangeRatioLower := and(shr(72, self), MASK_24_BITS)
        }
    }

    function rangeRatioUpper(Position self) internal pure returns (uint24 _rangeRatioUpper) {
        assembly ("memory-safe") {
            _rangeRatioUpper := and(shr(48, self), MASK_24_BITS)
        }
    }

    function thresholdRatioLower(Position self) internal pure returns (uint24 _thresholdRatioLower) {
        assembly ("memory-safe") {
            _thresholdRatioLower := and(shr(24, self), MASK_24_BITS)
        }
    }

    function thresholdRatioUpper(Position self) internal pure returns (uint24 _thresholdRatioUpper) {
        assembly ("memory-safe") {
            _thresholdRatioUpper := and(self, MASK_24_BITS)
        }
    }

    function from(
        uint128 _liquidity,
        uint24 _rangeRatioLower,
        uint24 _rangeRatioUpper,
        uint24 _thresholdRatioLower,
        uint24 _thresholdRatioUpper
    ) internal pure returns (Position position) {
        assembly ("memory-safe") {
            position :=
                or(
                    shl(128, _liquidity),
                    or(
                        or(shl(72, and(_rangeRatioLower, MASK_24_BITS)), shl(48, and(_rangeRatioUpper, MASK_24_BITS))),
                        or(shl(24, and(_thresholdRatioLower, MASK_24_BITS)), and(_thresholdRatioUpper, MASK_24_BITS))
                    )
                )
        }
    }
}
