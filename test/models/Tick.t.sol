// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test} from "forge-std/Test.sol";
import {Tick, TickLibrary} from "../../src/models/Tick.sol";
import {Order} from "../../src/models/Order.sol";
import {OrderId} from "../../src/models/OrderId.sol";

contract TickTest is Test {
    using TickLibrary for mapping(uint160 => Tick);

    mapping(uint160 => Tick) public ticks;
    mapping(OrderId => Order) public orders;

    function setUp() public {
        ticks.initialize();
    }

    function placeMockOrder(uint160 targetTick, uint160[] memory neighborTicks) internal returns (OrderId orderId) {
        TickLibrary.PlaceOrderParams memory params = TickLibrary.PlaceOrderParams({
            maker: address(this),
            zeroForOne: true,
            amount: 100,
            targetTick: targetTick,
            currentTick: 0,
            neighborTicks: neighborTicks
        });

        return ticks.placeOrder(params);
    }

    function verifyMockOrder(OrderId orderId, uint160 tick) internal view {
        assertEq(ticks[tick].orders[orderId].maker, address(this));
        assertEq(ticks[tick].orders[orderId].zeroForOne, true);
        assertEq(ticks[tick].orders[orderId].amount, 100);
    }

    function verifyTickLink(uint160 prevTick, uint160 targetTick, uint160 nextTick) internal view {
        if (prevTick == targetTick && nextTick == targetTick) {
            return;
        }
        if (prevTick == targetTick || nextTick == targetTick) {
            assertTrue(ticks[prevTick].next == nextTick, "prevTick.next != nextTick");
            assertTrue(ticks[nextTick].prev == prevTick, "nextTick.prev != prevTick");
        } else {
            assertTrue(ticks[prevTick].next == targetTick, "prevTick.next != targetTick");
            assertTrue(ticks[targetTick].prev == prevTick, "targetTick.prev != prevTick");
            assertTrue(ticks[targetTick].next == nextTick, "targetTick.next != nextTick");
            assertTrue(ticks[nextTick].prev == targetTick, "nextTick.prev != targetTick");
        }
    }

    function verfiyLink(uint256 tickNumber) internal view {
        uint160 nextTick = 0;
        for (uint256 i = 0; i < tickNumber; i++) {
            nextTick = ticks[nextTick].next;
        }

        assertEq(nextTick, type(uint160).max);

        uint160 prevTick = type(uint160).max;
        for (uint256 i = 0; i < tickNumber; i++) {
            prevTick = ticks[prevTick].prev;
        }

        assertEq(prevTick, 0);
    }

    function test_initialize_AlreadyInitialized() public {
        ticks[0].next = 100;
        ticks.initialize();
        assertEq(ticks[0].next, 100);

        ticks[type(uint160).max].next = 100;
        ticks.initialize();
        assertEq(ticks[type(uint160).max].next, 100);
    }

    function test_palceOrder_next() public {
        uint160[] memory neighborTicks = new uint160[](0);
        OrderId orderId = placeMockOrder(100, neighborTicks);

        verifyTickLink(0, 100, type(uint160).max);
        assertEq(orderId.index(), 1);
        assertEq(orderId.sqrtPriceX96(), 100);
        assertEq(ticks[100].totalAmountOpen, 100);
        assertEq(ticks[100].lastOpenOrder, 1);
        assertEq(ticks[100].lastCloseOrder, 0);

        verifyMockOrder(orderId, 100);

        orderId = placeMockOrder(100, neighborTicks);
        assertEq(ticks[100].totalAmountOpen, 200);
        assertEq(ticks[100].lastOpenOrder, 2);
        assertEq(ticks[100].orders[orderId].amount, 100);
        verifyMockOrder(orderId, 100);
    }

    function test_placeOrder_prev() public {
        uint160[] memory neighborTicks = new uint160[](0);

        OrderId orderId = placeMockOrder(1000, neighborTicks);
        placeMockOrder(500, neighborTicks);
        placeMockOrder(100, neighborTicks);

        verifyMockOrder(orderId, 1000);

        verifyTickLink(0, 100, 500);
        verifyTickLink(100, 500, 1000);
        verifyTickLink(500, 1000, type(uint160).max);
    }

    function test_fuzz_placeOrder(uint160 tick1, uint160 tick2, uint160 tick3) public {
        uint160[] memory neighborTicks = new uint160[](0);

        placeMockOrder(tick1, neighborTicks);
        placeMockOrder(tick2, neighborTicks);
        placeMockOrder(tick3, neighborTicks);

        verfiyLink(4);
    }
}
