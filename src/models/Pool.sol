// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {Tick} from "./Tick.sol";

struct Pool {
    uint160 sqrtPriceX96;
    uint160 sqrtPriceLowerX96;
    uint160 sqrtPriceUpperX96;
    uint128 liquidity;
    uint32 topAsk;
    uint32 topBid;
    mapping(uint32 => Tick) ticks;
}
