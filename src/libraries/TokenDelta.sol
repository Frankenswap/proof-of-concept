// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Token} from "../models/Token.sol";

library TokenDelta {
    function _computeSolt(address target, Token token) internal pure returns (bytes32 slot) {
        assembly ("memory-safe") {
            mstore(0, and(target, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(32, and(token, 0xffffffffffffffffffffffffffffffffffffffff))
            slot := keccak256(0, 64)
        }
    }

    function getDelta(Token token, address target) internal view returns (int256 delta) {
        bytes32 slot = _computeSolt(target, token);
        assembly ("memory-safe") {
            delta := tload(slot)
        }
    }

    function applyDelta(Token token, address target, int128 delta) internal returns (int256 previous, int256 next) {
        bytes32 slot = _computeSolt(target, token);

        assembly ("memory-safe") {
            previous := tload(slot)
        }
        next = previous + delta;
        assembly ("memory-safe") {
            tstore(slot, next)
        }
    }
}
