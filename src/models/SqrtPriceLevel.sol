// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Order} from "./Order.sol";
import {OrderId} from "./OrderId.sol";
import {SqrtPrice} from "./SqrtPrice.sol";

struct SqrtPriceLevel {
    SqrtPrice prev;
    SqrtPrice next;
    uint128 totalOpenAmount;
    uint64 lastOpenOrderIndex;
    uint64 lastCloseOrderIndex;
    mapping(OrderId => Order) orders;
}
