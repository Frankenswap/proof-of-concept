// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Layout: int128 amount0 | int128 amount1
type BalanceDelta is bytes32;

function toBalanceDelta(int128 _amount0, int128 _amount1) pure returns (BalanceDelta balanceDelta) {
    assembly ("memory-safe") {
        balanceDelta := or(shl(128, _amount0), and(sub(shl(128, 1), 1), _amount1))
    }
}
