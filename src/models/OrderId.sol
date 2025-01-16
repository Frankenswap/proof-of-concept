// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Layout: 160 sqrtPriceX96 | 96 order index
type OrderId is bytes32;

using OrderIdLibrary for OrderId global;

/// @title OrderIdLibrary
library OrderIdLibrary {
    uint96 internal constant MASK_96_BITS = 0xFFFFFFFFFFFFFFFFFFFFFFFF;

    // #### GETTERS ####
    function sqrtPriceX96(OrderId self) internal pure returns (uint160 _sqrtPriceX96) {
        assembly ("memory-safe") {
            _sqrtPriceX96 := shr(96, self)
        }
    }

    function index(OrderId self) internal pure returns (uint96 _index) {
        assembly ("memory-safe") {
            _index := and(self, MASK_96_BITS)
        }
    }

    function next(OrderId self) internal pure returns (OrderId nextOrderId) {
        assembly ("memory-safe") {
            nextOrderId := add(self, 1)
        }
    }

    // #### SETTERS ####
    function from(uint160 _sqrtPriceX96, uint96 _index) internal pure returns (OrderId self) {
        assembly ("memory-safe") {
            self := or(and(_index, MASK_96_BITS), shl(96, _sqrtPriceX96))
        }
    }
}
