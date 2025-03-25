// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SqrtPrice} from "./SqrtPrice.sol";

/// @dev Layout: uint160 sqrtPrice | 32 empty | uint64 index
type OrderId is bytes32;

using OrderIdLibrary for OrderId global;

/// @title OrderIdLibrary
library OrderIdLibrary {
    uint64 private constant MASK_64_BITS = 0xFFFFFFFFFFFFFFFF;

    // #### GETTERS ####
    function sqrtPrice(OrderId self) internal pure returns (SqrtPrice _sqrtPrice) {
        assembly ("memory-safe") {
            _sqrtPrice := shr(96, self)
        }
    }

    function index(OrderId self) internal pure returns (uint64 _index) {
        assembly ("memory-safe") {
            _index := and(self, MASK_64_BITS)
        }
    }

    function next(OrderId self) internal pure returns (OrderId _next) {
        assembly ("memory-safe") {
            _next := add(self, 1)
        }
    }

    // #### SETTERS ####
    function from(SqrtPrice _sqrtPrice, uint64 _index) internal pure returns (OrderId orderId) {
        assembly ("memory-safe") {
            orderId := or(shl(96, _sqrtPrice), and(_index, MASK_64_BITS))
        }
    }
}
