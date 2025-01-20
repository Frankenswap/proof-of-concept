// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {Position} from "./Position.sol";
import {Tick} from "./Tick.sol";

struct Pool {
    uint160 sqrtPriceX96;
    Position position;
    uint160 topAsk;
    uint160 topBid;
    mapping(uint160 => Tick) ticks;
}
