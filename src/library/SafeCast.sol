// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    error SafeCastOverflow();

    function toInt128(uint128 x) internal pure returns (int128 y) {
        y = int128(x);
        if (y < 0) revert SafeCastOverflow();
    }

    function toUint128(uint256 x) internal pure returns (uint128 y) {
        y = uint128(x);
        if (y != x) revert SafeCastOverflow();
    }

    function toUint160(uint256 x) internal pure returns (uint160 y) {
        y = uint160(x);
        if (y != x) revert SafeCastOverflow();
    }

    function uint256toInt128(uint256 x) internal pure returns (int128) {
        if (x >= 1 << 127) revert SafeCastOverflow();
        return int128(int256(x));
    }
}
