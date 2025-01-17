// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Order} from "./Order.sol";
import {OrderId} from "./OrderId.sol";

struct Tick {
    uint64 lastOpenOrder;
    uint64 lastCloseOrder;
    uint128 totalAmountOpen;
    uint32 prev;
    uint32 next;
    mapping(OrderId => Order) orders;
}
