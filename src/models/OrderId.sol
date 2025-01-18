// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Layout: 32 tick (uint32) | 160 pool id (PoolId) | 64 index (uint64)
type OrderId is bytes32;

using OrderIdLibrary for OrderId global;

/// @title OrderIdLibrary
library OrderIdLibrary {
    uint160 internal constant MASK_160_BITS = 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint96 internal constant MASK_64_BITS = 0xFFFFFFFFFFFFFFFF;

    // #### GETTERS ####
    function tick(OrderId self) internal pure returns (uint32 _tick) {
        assembly ("memory-safe") {
            _tick := shr(224, self)
        }
    }

    function poolId(OrderId self) internal pure returns (uint160 _poolId) {
        assembly ("memory-safe") {
            _poolId := and(MASK_160_BITS, shr(64, self))
        }
    }

    function index(OrderId self) internal pure returns (uint64 _index) {
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
    function from(uint32 _tick, uint160 _poolId, uint64 _index) internal pure returns (OrderId self) {
        assembly ("memory-safe") {
            self := or(or(and(_index, MASK_64_BITS), shl(64, and(_poolId, MASK_160_BITS))), shl(224, _tick))
        }
    }
}
