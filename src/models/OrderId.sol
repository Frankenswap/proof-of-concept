// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Layout: 160 sqrtPrice (uint160) | 32 empty | 64 index (uint64)
type OrderId is bytes32;

using OrderIdLibrary for OrderId global;

/// @title OrderIdLibrary
library OrderIdLibrary {
    uint96 internal constant MASK_64_BITS = 0xFFFFFFFFFFFFFFFF;

    // #### GETTERS ####
    function sqrtPriceX96(OrderId self) internal pure returns (uint160 _sqrtPriceX96) {
        assembly ("memory-safe") {
            _sqrtPriceX96 := shr(96, self)
        }
    }

    function index(OrderId self) internal pure returns (uint96 _index) {
        assembly ("memory-safe") {
            _index := and(self, MASK_64_BITS)
        }
    }

    function next(OrderId self) internal pure returns (OrderId nextOrderId) {
        assembly ("memory-safe") {
            nextOrderId := add(self, 1)
        }
    }

    // #### SETTERS ####
    function from(uint160 _sqrtPriceX96, uint64 _index) internal pure returns (OrderId self) {
        assembly ("memory-safe") {
            self := or(and(_index, MASK_64_BITS), shl(96, _sqrtPriceX96))
        }
    }
}
