// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Order} from "./Order.sol";
import {OrderId} from "./OrderId.sol";

struct Tick {
    uint32 prev;
    uint32 next;
    uint128 totalAmountOpen;
    uint64 lastOpenOrder;
    uint64 lastCloseOrder;
    mapping(OrderId => Order) orders;
}

using TickLibrary for Tick global;

/// @title TickLibrary
library TickLibrary {
    function insert(
        mapping(uint160 => Tick) storage self,
        uint160 sqrtPriceX96,
        uint160 insertPriceX96,
        Tick memory insertTick
    ) internal {
        uint160 nextTick = self[sqrtPriceX96].nextSqrtPriceX96;

        if (nextTick == 0) {
            self[sqrtPriceX96].nextSqrtPriceX96 = insertPriceX96;
        } else {
            uint160 cacheTick = self[sqrtPriceX96].nextSqrtPriceX96;

            self[sqrtPriceX96].nextSqrtPriceX96 = insertPriceX96;
            self[cacheTick].prevSqrtPriceX96 = insertPriceX96;
        }

        self[insertPriceX96] = insertTick;
    }

    function update(
        mapping(uint160 => Tick) storage self,
        uint160 sqrtPriceX96,
        int128 amountDelta,
        uint64 orderCountDelta,
        uint64 orderWatermark
    ) internal {
        unchecked {
            self[sqrtPriceX96].amountTotal += amountDelta;
            self[sqrtPriceX96].orderCount += orderCountDelta;
            self[sqrtPriceX96].orderWatermark = orderWatermark;
        }
    }

    function checkInitilize(mapping(uint160 => Tick) storage self, uint160 sqrtPriceX96)
        internal
        view
        returns (bool isInitilized)
    {
        assembly ("memory-safe") {
            mstore(0, sqrtPriceX96)
            mstore(0x20, self.slot)
            let slot := keccak256(0, 0x40)

            isInitilized := gt(sload(add(slot, 2)), 0)
        }
    }

    function checkRange(mapping(uint160 => Tick) storage self, uint160 prevSqrtPriceX96, uint160 sqrtPriceX96)
        internal
        view
        returns (bool)
    {
        uint160 nextSqrtPriceX96 = self[prevSqrtPriceX96].nextSqrtPriceX96;

        if (prevSqrtPriceX96 < sqrtPriceX96 && sqrtPriceX96 < nextSqrtPriceX96) {
            return true;
        }

        return false;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Order} from "./Order.sol";
import {OrderId} from "./OrderId.sol";

struct Tick {
    uint32 prev;
    uint32 next;
    uint128 totalAmountOpen;
    uint64 lastOpenOrder;
    uint64 lastCloseOrder;
    mapping(OrderId => Order) orders;
}
