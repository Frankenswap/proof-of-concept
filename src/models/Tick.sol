// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Tick {
    uint160 tickPrev; // TODO: 128 bit
    uint160 tickNext;
    uint128 amountTotal;
    uint64 orderCount;
    uint64 orderWatermark;
}

using TickLibrary for Tick global;

/// @title TickLibrary
library TickLibrary {
    function insertAfter(
        mapping(uint160 => Tick) storage self,
        uint160 nowTick,
        uint160 tickNext,
        Tick memory insertTick
    ) internal {
        uint160 nextTick = self[nowTick].tickNext;

        if (nextTick == 0) {
            self[nowTick].tickNext = tickNext;
        } else {
            uint160 cacheTick = self[nowTick].tickNext;

            self[nowTick].tickNext = tickNext;
            self[cacheTick].tickPrev = tickNext;
        }

        self[tickNext] = insertTick;
    }

    function getAfterTick(mapping(uint160 => Tick) storage self, uint160 nowTick)
        internal
        view
        returns (Tick memory tick)
    {
        // TODO: Gas optimization. Use assembly get tickNext
        tick = self[self[nowTick].tickNext];
    }
}
