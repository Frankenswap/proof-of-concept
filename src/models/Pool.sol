// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {Tick} from "./Tick.sol";

struct Pool {
    uint160 sqrtPriceX96;
    uint128 liquidity;
    uint128 thresholdRatioLowerX96;
    uint128 liquidityRangeRatioLowerX96;
    uint128 thresholdRatioUpperX96;
    uint128 liquidityRangeRatioUpperX96;
    uint160 topAsk;
    uint160 topBid;
    mapping(uint160 => Tick) ticks;
}
