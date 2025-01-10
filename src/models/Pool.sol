// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {Order} from "./Order.sol";
import {OrderId} from "./OrderId.sol";
import {Tick} from "./Tick.sol";

struct Pool {
    address lastRebaser;
    uint256 lastRebasedBlock;
    uint160 sqrtPriceX96;
    uint128 counterAmount0;
    uint128 counterAmount1;
    uint160 sqrtPriceLowerX96;
    uint160 sqrtPriceUpperX96;
    uint128 liquidityLower;
    uint128 liquidityUpper;
    uint160 nextTickLower;
    uint160 nextTickUpper;
    mapping(uint160 => Tick) ticks;
    mapping(OrderId => Order) orders;
}

using PoolLibrary for Pool global;

/// @title PoolLibrary
library PoolLibrary {}
