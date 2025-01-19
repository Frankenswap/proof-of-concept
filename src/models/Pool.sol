// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {Tick} from "./Tick.sol";

struct Pool {
    uint160 sqrtPriceX96;
    uint160 sqrtPriceLowerX96;
    uint160 sqrtPriceUpperX96;
    uint160 topAsk;
    uint160 topBid;
    uint128 liquidity;
    mapping(uint160 => Tick) ticks;
}
