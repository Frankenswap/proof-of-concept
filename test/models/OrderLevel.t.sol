// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test} from "forge-std/Test.sol";
import {OrderLevel, OrderLevelLibrary} from "../../src/models/OrderLevel.sol";
import {SqrtPrice} from "../../src/models/SqrtPrice.sol";
import {Order} from "../../src/models/Order.sol";
import {OrderId} from "../../src/models/OrderId.sol";

contract OrderLevelTest is Test {
    using OrderLevelLibrary for mapping(SqrtPrice => OrderLevel);

    mapping(SqrtPrice => OrderLevel) public ticks;
    mapping(OrderId => Order) public orders;

    function setUp() public {
        ticks.initialize();
    }

    function placeMockOrder(SqrtPrice targetTick, SqrtPrice[] memory neighborTicks)
        internal
        returns (OrderId orderId)
    {
        OrderLevelLibrary.PlaceOrderParams memory params = OrderLevelLibrary.PlaceOrderParams({
            maker: address(this),
            zeroForOne: true,
            amount: 100,
            targetTick: targetTick,
            currentTick: SqrtPrice.wrap(0),
            neighborTicks: neighborTicks
        });

        return ticks.placeOrder(params);
    }

    function verifyMockOrder(OrderId orderId, SqrtPrice tick) internal view {
        assertEq(ticks[tick].orders[orderId].maker, address(this));
        assertEq(ticks[tick].orders[orderId].zeroForOne, true);
        assertEq(ticks[tick].orders[orderId].amount, 100);
    }

    function verifyTickLink(SqrtPrice prevTick, SqrtPrice targetTick, SqrtPrice nextTick) internal view {
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
        SqrtPrice nextTick = SqrtPrice.wrap(0);
        for (uint256 i = 0; i < tickNumber; i++) {
            nextTick = ticks[nextTick].next;
        }

        assertEq(SqrtPrice.unwrap(nextTick), type(uint160).max);

        SqrtPrice prevTick = SqrtPrice.wrap(type(uint160).max);
        for (uint256 i = 0; i < tickNumber; i++) {
            prevTick = ticks[prevTick].prev;
        }

        assertEq(SqrtPrice.unwrap(prevTick), 0);
    }

    function test_initialize_AlreadyInitialized() public {
        ticks[SqrtPrice.wrap(0)].next = SqrtPrice.wrap(100);
        vm.expectRevert(OrderLevelLibrary.OrderLevelAlreadyInitialized.selector);
        ticks.initialize();
        assertEq(SqrtPrice.unwrap(ticks[SqrtPrice.wrap(0)].next), 100);

        ticks[SqrtPrice.wrap(type(uint160).max)].next = SqrtPrice.wrap(100);
        ticks.initialize();
        vm.expectRevert(OrderLevelLibrary.OrderLevelAlreadyInitialized.selector);
        assertEq(SqrtPrice.unwrap(ticks[SqrtPrice.wrap(type(uint160).max)].next), 100);
    }

    function test_palceOrder_next() public {
        SqrtPrice[] memory neighborTicks = new SqrtPrice[](0);
        SqrtPrice targetTick = SqrtPrice.wrap(100);
        OrderId orderId = placeMockOrder(targetTick, neighborTicks);

        verifyTickLink(SqrtPrice.wrap(0), targetTick, SqrtPrice.wrap(type(uint160).max));
        assertEq(orderId.index(), 1);
        assertEq(SqrtPrice.unwrap(orderId.sqrtPrice()), 100);
        assertEq(ticks[targetTick].totalOpenAmount, 100);
        assertEq(ticks[targetTick].lastOpenOrderIndex, 1);
        assertEq(ticks[targetTick].lastCloseOrderIndex, 0);

        verifyMockOrder(orderId, targetTick);

        orderId = placeMockOrder(targetTick, neighborTicks);
        assertEq(ticks[targetTick].totalOpenAmount, 200);
        assertEq(ticks[targetTick].lastOpenOrderIndex, 2);
        assertEq(ticks[targetTick].orders[orderId].amount, 100);
        verifyMockOrder(orderId, targetTick);
    }

    function test_placeOrder_prev() public {
        SqrtPrice[] memory neighborTicks = new SqrtPrice[](0);

        OrderId orderId = placeMockOrder(SqrtPrice.wrap(1000), neighborTicks);
        placeMockOrder(SqrtPrice.wrap(500), neighborTicks);
        placeMockOrder(SqrtPrice.wrap(100), neighborTicks);

        verifyMockOrder(orderId, SqrtPrice.wrap(1000));

        verifyTickLink(SqrtPrice.wrap(0), SqrtPrice.wrap(100), SqrtPrice.wrap(500));
        verifyTickLink(SqrtPrice.wrap(100), SqrtPrice.wrap(500), SqrtPrice.wrap(1000));
        verifyTickLink(SqrtPrice.wrap(500), SqrtPrice.wrap(1000), SqrtPrice.wrap(type(uint160).max));
    }

    function test_fuzz_placeOrder(SqrtPrice tick1, SqrtPrice tick2, SqrtPrice tick3) public {
        SqrtPrice[] memory neighborTicks = new SqrtPrice[](0);

        placeMockOrder(tick1, neighborTicks);
        placeMockOrder(tick2, neighborTicks);
        placeMockOrder(tick3, neighborTicks);

        verfiyLink(4);
    }
}
