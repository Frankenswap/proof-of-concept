// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Token} from "../models/Token.sol";

library TokenDelta {
    function _computeSolt(address target, Token token) internal pure returns (bytes32 solt) {
        assembly ("memory-safe") {
            mstore(0, and(target, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(32, and(token, 0xffffffffffffffffffffffffffffffffffffffff))
            solt := keccak256(0, 64)
        }
    }

    function getDelta(Token token, address target) internal view returns (int256 delta) {
        bytes32 solt = _computeSolt(target, token);
        assembly ("memory-safe") {
            delta := tload(solt)
        }
    }

    function applyDelta(Token token, address target, int256 delta) internal returns (int256 previous, int256 next) {
        bytes32 solt = _computeSolt(target, token);

        assembly ("memory-safe") {
            previous := tload(solt)
        }
        next = previous + delta;
        assembly ("memory-safe") {
            tstore(solt, next)
        }
    }
}