// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Tick {
    uint32 prev;
    uint32 next;
    uint32 lastOpenOrder;
    uint32 lastCloseOrder;
    uint128 totalAmount;
}
