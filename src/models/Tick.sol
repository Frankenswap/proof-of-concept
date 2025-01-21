// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Order} from "./Order.sol";
import {OrderId, OrderIdLibrary} from "./OrderId.sol";

struct Tick {
    uint160 prev;
    uint160 next;
    uint128 totalAmountOpen;
    uint64 lastOpenOrder;
    uint64 lastCloseOrder;
    mapping(OrderId => Order) orders;
}

using TickLibrary for Tick global;

/// @title TickLibrary
library TickLibrary {
    function initialize(Tick storage self, uint160 prev, uint160 next) internal {
        self.prev = prev;
        self.next = next;
    }

    struct PlaceOrderParams {
        address maker;
        bool zeroForOne;
        uint128 amount;
        uint160 targetTick;
        uint160 currentTick;
        uint160[] neighborTicks;
    }

    function placeOrder(mapping(uint160 => Tick) storage self, PlaceOrderParams memory params)
        internal
        returns (OrderId orderId)
    {
        uint160 neighborTick;
        uint160 neighborPrev;
        uint160 neighborNext;
        uint160[] memory neighborTicks = params.neighborTicks;

        assembly ("memory-safe") {
            let len := mload(neighborTicks)

            for { let i := 0 } lt(i, len) { i := add(i, 1) } {
                let readTick := mload(add(add(neighborTicks, 0x20), shl(5, i)))

                mstore(0, readTick)
                mstore(0x20, self.slot)

                let slot := keccak256(0, 0x40)
                let readData := sload(add(slot, 2))

                if gt(shr(128, readData), 0) {
                    neighborTick := readTick

                    neighborPrev := sload(slot)
                    neighborNext := sload(add(slot, 1))

                    break
                }
            }

            if iszero(neighborTick) {
                neighborTick := mload(add(params, 0x80))

                mstore(0, neighborTick)
                mstore(0x20, self.slot)

                let slot := keccak256(0, 0x40)
                neighborPrev := sload(slot)
                neighborNext := sload(add(slot, 1))
            }
        }

        uint160 targetTick = params.targetTick;

        if (neighborTick < targetTick) {
            uint160 nextTick = self[neighborTick].next;

            while (nextTick < targetTick) {
                nextTick = self[nextTick].next;
            }

            if (nextTick != targetTick) {
                uint160 cachePrevTick = self[nextTick].prev;

                self[targetTick].next = nextTick;
                self[targetTick].prev = cachePrevTick;
                self[cachePrevTick].next = targetTick;
                self[nextTick].prev = targetTick;
            }
        }

        self[targetTick].lastOpenOrder += 1;
        self[targetTick].totalAmountOpen += params.amount;

        orderId = OrderIdLibrary.from(params.targetTick, self[targetTick].lastOpenOrder);
        self[targetTick].orders[orderId].initialize(params.maker, params.zeroForOne, params.amount);
    }
}
