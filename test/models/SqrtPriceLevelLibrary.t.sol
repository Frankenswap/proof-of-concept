// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test} from "forge-std/Test.sol";
import {SqrtPriceLevel, SqrtPriceLevelLibrary} from "../../src/models/SqrtPriceLevel.sol";
import {SqrtPrice} from "../../src/models/SqrtPrice.sol";
import {Order} from "../../src/models/Order.sol";
import {OrderId} from "../../src/models/OrderId.sol";

import {console} from "forge-std/console.sol";

contract SqrtPriceLevelTest is Test {
    using SqrtPriceLevelLibrary for mapping(SqrtPrice => SqrtPriceLevel);

    mapping(SqrtPrice => SqrtPriceLevel) public ticks;
    mapping(OrderId => Order) public orders;

    function setUp() public {
        ticks.initialize();
    }

    function placeMockOrder(SqrtPrice targetTick, uint128 amount, SqrtPrice[] memory neighborTicks)
        internal
        returns (OrderId orderId)
    {
        SqrtPriceLevelLibrary.PlaceOrderParams memory params = SqrtPriceLevelLibrary.PlaceOrderParams({
            maker: address(this),
            zeroForOne: true,
            amount: amount,
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

    function verfiyLink(uint256 tickNumber, uint256 targetOrderCount, uint256 totalOrderAmount) internal view {
        SqrtPrice nextTick = SqrtPrice.wrap(0);
        uint256 orderCount = ticks[nextTick].lastOpenOrder - ticks[nextTick].lastCloseOrder;
        uint256 orderAmount = ticks[nextTick].totalOpenAmount;

        for (uint256 i = 0; i < tickNumber; i++) {
            nextTick = ticks[nextTick].next;

            orderCount += ticks[nextTick].lastOpenOrder - ticks[nextTick].lastCloseOrder;
            orderAmount += ticks[nextTick].totalOpenAmount;

            if (nextTick == SqrtPrice.wrap(type(uint160).max)) {
                break;
            }
        }

        assertEq(SqrtPrice.unwrap(nextTick), type(uint160).max);
        assertEq(targetOrderCount, orderCount);
        assertEq(totalOrderAmount, orderAmount);

        SqrtPrice prevTick = SqrtPrice.wrap(type(uint160).max);
        for (uint256 i = 0; i < tickNumber; i++) {
            prevTick = ticks[prevTick].prev;
        }

        assertEq(SqrtPrice.unwrap(prevTick), 0);
    }

    function test_initialize_AlreadyInitialized() public {
        ticks[SqrtPrice.wrap(0)].next = SqrtPrice.wrap(100);
        vm.expectRevert(SqrtPriceLevelLibrary.SqrtPriceLevelAlreadyInitialized.selector);
        ticks.initialize();
        assertEq(SqrtPrice.unwrap(ticks[SqrtPrice.wrap(0)].next), 100);

        ticks[SqrtPrice.wrap(type(uint160).max)].next = SqrtPrice.wrap(100);
        ticks.initialize();
        vm.expectRevert(SqrtPriceLevelLibrary.SqrtPriceLevelAlreadyInitialized.selector);
        assertEq(SqrtPrice.unwrap(ticks[SqrtPrice.wrap(type(uint160).max)].next), 100);
    }

    function test_palceOrder_next() public {
        SqrtPrice[] memory neighborTicks = new SqrtPrice[](0);
        SqrtPrice targetTick = SqrtPrice.wrap(100);
        OrderId orderId = placeMockOrder(targetTick, 100, neighborTicks);

        verifyTickLink(SqrtPrice.wrap(0), targetTick, SqrtPrice.wrap(type(uint160).max));
        assertEq(orderId.index(), 1);
        assertEq(SqrtPrice.unwrap(orderId.sqrtPrice()), 100);
        assertEq(ticks[targetTick].totalOpenAmount, 100);
        assertEq(ticks[targetTick].lastOpenOrder, 1);
        assertEq(ticks[targetTick].lastCloseOrder, 0);

        verifyMockOrder(orderId, targetTick);

        orderId = placeMockOrder(targetTick, 100, neighborTicks);
        assertEq(ticks[targetTick].totalOpenAmount, 200);
        assertEq(ticks[targetTick].lastOpenOrder, 2);
        assertEq(ticks[targetTick].orders[orderId].amount, 100);
        verifyMockOrder(orderId, targetTick);
    }

    function test_placeOrder_prev() public {
        SqrtPrice[] memory neighborTicks = new SqrtPrice[](0);

        OrderId orderId = placeMockOrder(SqrtPrice.wrap(1000), 100, neighborTicks);
        placeMockOrder(SqrtPrice.wrap(500), 100, neighborTicks);
        placeMockOrder(SqrtPrice.wrap(100), 100, neighborTicks);

        verifyMockOrder(orderId, SqrtPrice.wrap(1000));

        verifyTickLink(SqrtPrice.wrap(0), SqrtPrice.wrap(100), SqrtPrice.wrap(500));
        verifyTickLink(SqrtPrice.wrap(100), SqrtPrice.wrap(500), SqrtPrice.wrap(1000));
        verifyTickLink(SqrtPrice.wrap(500), SqrtPrice.wrap(1000), SqrtPrice.wrap(type(uint160).max));
    }

    struct PlaceMockOrderParams {
        SqrtPrice targetTick;
        uint32 amount;
    }

    function test_fuzz_placeOrder(
        PlaceMockOrderParams calldata tick1,
        PlaceMockOrderParams calldata tick2,
        PlaceMockOrderParams calldata tick3
    ) public {
        SqrtPrice[] memory neighborTicks = new SqrtPrice[](0);

        placeMockOrder(tick1.targetTick, tick1.amount, neighborTicks);
        placeMockOrder(tick2.targetTick, tick2.amount, neighborTicks);
        placeMockOrder(tick3.targetTick, tick3.amount, neighborTicks);

        verfiyLink(4, 3, uint256(tick1.amount) + tick2.amount + tick3.amount);
    }
}
