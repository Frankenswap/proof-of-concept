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
