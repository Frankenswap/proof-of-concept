// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test} from "forge-std/Test.sol";
import {Tick, TickLibrary} from "../../src/models/Tick.sol";

contract TickTest is Test {
    using TickLibrary for mapping(uint160 => Tick);

    mapping(uint160 => Tick) public ticks;

    function setUp() public {
        ticks[0] = Tick({prevSqrtPriceX96: 0, nextSqrtPriceX96: 0, amountTotal: 1, orderCount: 1, orderWatermark: 0});
    }

    function test_insert_NextIsZero() public {
        Tick memory tick =
            Tick({prevSqrtPriceX96: 0, nextSqrtPriceX96: 0, amountTotal: 0, orderCount: 0, orderWatermark: 0});
        ticks.insert(0, 100, tick);

        assertEq(ticks[100].prevSqrtPriceX96, 0);
        assertEq(ticks[0].nextSqrtPriceX96, 100);
    }

    function test_insert_NextIsNotZero() public {
        ticks[0] = Tick({prevSqrtPriceX96: 0, nextSqrtPriceX96: 100, amountTotal: 0, orderCount: 0, orderWatermark: 0});
        ticks[100] = Tick({prevSqrtPriceX96: 0, nextSqrtPriceX96: 0, amountTotal: 0, orderCount: 0, orderWatermark: 0});

        Tick memory tick =
            Tick({prevSqrtPriceX96: 0, nextSqrtPriceX96: 100, amountTotal: 0, orderCount: 0, orderWatermark: 0});
        ticks.insert(0, 50, tick);

        assertEq(ticks[0].nextSqrtPriceX96, 50);
        assertEq(ticks[100].prevSqrtPriceX96, 50);
    }

    function test_checkInitilize() public view {
        assertEq(ticks.checkInitilize(0), true);
        assertEq(ticks.checkInitilize(1), false);
    }

    function test_fuzz_checkInitilize(uint160 sqrtPriceX96) public {
        vm.assume(sqrtPriceX96 != 0);
        assertEq(ticks.checkInitilize(sqrtPriceX96), false);
        ticks[sqrtPriceX96] =
            Tick({prevSqrtPriceX96: 0, nextSqrtPriceX96: 0, amountTotal: 0, orderCount: 1, orderWatermark: 0});

        assertEq(ticks.checkInitilize(sqrtPriceX96), true);
    }

    function test_fuzz_update(uint160 sqrtPriceX96, int128 amountDelta, uint64 orderCountDelta, uint64 orderWatermark)
        public
    {
        vm.assume(sqrtPriceX96 != 0);
        ticks.update(sqrtPriceX96, amountDelta, orderCountDelta, orderWatermark);

        assertEq(ticks[sqrtPriceX96].amountTotal, amountDelta);
        assertEq(ticks[sqrtPriceX96].orderCount, orderCountDelta);
        assertEq(ticks[sqrtPriceX96].orderWatermark, orderWatermark);
    }
}
