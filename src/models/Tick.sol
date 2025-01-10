// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Tick {
    uint160 tickPrev;
    uint160 tickNext;
    uint128 amountTotal;
    uint64 orderCount;
    uint64 orderWatermark;
}

using TickLibrary for Tick global;

/// @title TickLibrary
library TickLibrary {}
