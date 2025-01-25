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
}
