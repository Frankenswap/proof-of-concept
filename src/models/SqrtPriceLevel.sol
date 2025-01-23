// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Order} from "./Order.sol";
import {OrderId, OrderIdLibrary} from "./OrderId.sol";
import {SqrtPrice} from "./SqrtPrice.sol";

struct SqrtPriceLevel {
    SqrtPrice prev;
    SqrtPrice next;
    uint128 totalOpenAmount;
    uint64 lastOpenOrder;
    uint64 lastCloseOrder;
    mapping(OrderId => Order) orders;
}

using SqrtPriceLevelLibrary for SqrtPriceLevel global;

/// @title SqrtPriceLevelLibrary
library SqrtPriceLevelLibrary {
    function initialize(mapping(SqrtPrice => SqrtPriceLevel) storage self) internal {
        if (self[SqrtPrice.wrap(0)].next != SqrtPrice.wrap(0)) return;
        if (self[SqrtPrice.wrap(type(uint160).max)].next != SqrtPrice.wrap(0)) return;

        self[SqrtPrice.wrap(0)].next = SqrtPrice.wrap(type(uint160).max);
        self[SqrtPrice.wrap(type(uint160).max)].next = SqrtPrice.wrap(type(uint160).max);
    }

    struct PlaceOrderParams {
        address maker;
        bool zeroForOne;
        uint128 amount;
        SqrtPrice targetTick;
        SqrtPrice currentTick;
        SqrtPrice[] neighborTicks;
    }

    function placeOrder(mapping(SqrtPrice => SqrtPriceLevel) storage self, PlaceOrderParams memory params)
        internal
        returns (OrderId orderId)
    {
        SqrtPrice neighborTick;
        SqrtPrice neighborPrev;
        SqrtPrice neighborNext;
        SqrtPrice[] memory neighborTicks = params.neighborTicks;

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

        SqrtPrice targetTick = params.targetTick;

        if (neighborTick < targetTick) {
            SqrtPrice nextTick = self[neighborTick].next;

            while (nextTick < targetTick) {
                nextTick = self[nextTick].next;
            }

            // If nextTick == targetTick, targetTick is in the tick link, so do nothing
            // If nextTick != targetTick, targetTick is not in the tick link, so update the tick link
            if (nextTick != targetTick) {
                SqrtPrice cachePrevTick = self[nextTick].prev;

                self[cachePrevTick].next = targetTick;
                self[targetTick].next = nextTick;

                self[nextTick].prev = targetTick;
                self[targetTick].prev = cachePrevTick;
            }
        }

        if (neighborTick > targetTick) {
            SqrtPrice prevTick = self[neighborTick].prev;

            while (prevTick > targetTick) {
                prevTick = self[prevTick].prev;
            }

            if (prevTick != targetTick) {
                SqrtPrice cacheNextTick = self[prevTick].next;

                self[prevTick].next = targetTick;
                self[targetTick].next = cacheNextTick;

                self[cacheNextTick].prev = targetTick;
                self[targetTick].prev = prevTick;
            }
        }

        self[targetTick].lastOpenOrder += 1;
        self[targetTick].totalOpenAmount += params.amount;

        orderId = OrderIdLibrary.from(params.targetTick, self[targetTick].lastOpenOrder);
        self[targetTick].orders[orderId].initialize(params.maker, params.zeroForOne, params.amount);
    }
}
