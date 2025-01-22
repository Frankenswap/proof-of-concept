// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Order} from "./Order.sol";
import {OrderId} from "./OrderId.sol";
import {SqrtPrice} from "./SqrtPrice.sol";

struct SqrtPriceLevel {
    SqrtPrice prev;
    SqrtPrice next;
    uint128 totalOpenAmount;
    uint64 lastOpenOder;
    uint64 lastCloseOrder;
    mapping(OrderId => Order) orders;
}
