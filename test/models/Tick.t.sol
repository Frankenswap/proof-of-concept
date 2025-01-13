// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test} from "forge-std/Test.sol";
import {Tick, TickLibrary} from "../../src/models/Tick.sol";

contract TickTest is Test {
    using TickLibrary for mapping(uint160 => Tick);

    mapping(uint160 => Tick) public ticks;

    function setUp() public {
        ticks[0] = Tick({tickPrev: 0, tickNext: 0, amountTotal: 0, orderCount: 0, orderWatermark: 0});
    }

    function test_insertAfter_NextIsZero() public {
        Tick memory tick = Tick({tickPrev: 0, tickNext: 0, amountTotal: 0, orderCount: 0, orderWatermark: 0});
        ticks.insertAfter(0, 100, tick);

        assertEq(ticks[100].tickPrev, 0);
        assertEq(ticks[0].tickNext, 100);
    }

    function test_insertAfter_NextIsNotZero() public {
        ticks[0] = Tick({tickPrev: 0, tickNext: 100, amountTotal: 0, orderCount: 0, orderWatermark: 0});
        ticks[100] = Tick({tickPrev: 0, tickNext: 0, amountTotal: 0, orderCount: 0, orderWatermark: 0});

        Tick memory tick = Tick({tickPrev: 0, tickNext: 100, amountTotal: 0, orderCount: 0, orderWatermark: 0});
        ticks.insertAfter(0, 50, tick);

        assertEq(ticks[0].tickNext, 50);
        assertEq(ticks[100].tickPrev, 50);
    }
}
