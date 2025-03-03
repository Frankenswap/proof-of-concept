// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library UnsafeMath {
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}
