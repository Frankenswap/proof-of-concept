// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test} from "forge-std/Test.sol";
import {OrderLevel, OrderLevelLibrary} from "../../src/models/OrderLevel.sol";
import {SqrtPrice} from "../../src/models/SqrtPrice.sol";
import {Price, PriceLibrary} from "../../src/models/Price.sol";
import {Order} from "../../src/models/Order.sol";
import {OrderId, OrderIdLibrary} from "../../src/models/OrderId.sol";
import {BalanceDelta, toBalanceDelta} from "../../src/models/BalanceDelta.sol";

contract OrderLevelTest is Test {
    using OrderLevelLibrary for mapping(SqrtPrice => OrderLevel);

    mapping(SqrtPrice => OrderLevel) public ticks;
    mapping(OrderId => Order) public orders;

    function setUp() public {
        ticks.initialize();
    }

    function placeMockOrder(SqrtPrice targetTick, uint128 amount, SqrtPrice[] memory neighborTicks)
        internal
        returns (OrderId orderId)
    {
        OrderLevelLibrary.PlaceOrderParams memory params = OrderLevelLibrary.PlaceOrderParams({
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
        uint256 orderCount = ticks[nextTick].lastOpenOrderIndex - ticks[nextTick].lastCloseOrderIndex;
        uint256 orderAmount = ticks[nextTick].totalOpenAmount;

        for (uint256 i = 0; i < tickNumber; i++) {
            nextTick = ticks[nextTick].next;

            orderCount += ticks[nextTick].lastOpenOrderIndex - ticks[nextTick].lastCloseOrderIndex;
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

    /// forge-config: default.allow_internal_expect_revert = true
    function test_initialize_AlreadyInitialized() public {
        ticks[SqrtPrice.wrap(0)].next = SqrtPrice.wrap(100);
        vm.expectRevert(OrderLevelLibrary.OrderLevelAlreadyInitialized.selector);
        ticks.initialize();
        assertEq(SqrtPrice.unwrap(ticks[SqrtPrice.wrap(0)].next), 100);

        ticks[SqrtPrice.wrap(type(uint160).max)].next = SqrtPrice.wrap(100);

        vm.expectRevert(OrderLevelLibrary.OrderLevelAlreadyInitialized.selector);
        ticks.initialize();

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
        assertEq(ticks[targetTick].lastOpenOrderIndex, 1);
        assertEq(ticks[targetTick].lastCloseOrderIndex, 0);

        verifyMockOrder(orderId, targetTick);

        orderId = placeMockOrder(targetTick, 100, neighborTicks);
        assertEq(ticks[targetTick].totalOpenAmount, 200);
        assertEq(ticks[targetTick].lastOpenOrderIndex, 2);
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

    function test_removeOrder_underClose() public {
        SqrtPrice[] memory neighborTicks = new SqrtPrice[](0);

        // Remove zeroForOne = true
        OrderLevelLibrary.PlaceOrderParams memory params = OrderLevelLibrary.PlaceOrderParams({
            maker: address(this),
            zeroForOne: true,
            amount: 10 ether,
            targetTick: SqrtPrice.wrap(100),
            currentTick: SqrtPrice.wrap(0),
            neighborTicks: neighborTicks
        });

        OrderId orderId = ticks.placeOrder(params);
        ticks[SqrtPrice.wrap(100)].lastCloseOrderIndex = 1;

        (address maker, BalanceDelta delta) = ticks.removeOrder(orderId);
        assertEq(maker, address(this));
        assertEq(BalanceDelta.unwrap(delta), BalanceDelta.unwrap(toBalanceDelta(0, 10 ether)));

        // Remove zeroForOne = fasle
        params.zeroForOne = false;
        orderId = ticks.placeOrder(params);
        ticks[SqrtPrice.wrap(100)].lastCloseOrderIndex = 2;
        (maker, delta) = ticks.removeOrder(orderId);
        assertEq(maker, address(this));
        assertEq(BalanceDelta.unwrap(delta), BalanceDelta.unwrap(toBalanceDelta(10 ether, 0)));

        // Remove already closed order will be not affect
        (, delta) = ticks.removeOrder(orderId);
        assertEq(BalanceDelta.unwrap(delta), BalanceDelta.unwrap(toBalanceDelta(0, 0)));
    }

    function test_removeOrder_removeLink() public {
        SqrtPrice[] memory neighborTicks = new SqrtPrice[](0);
        // sqrt price = 2, price = 4
        OrderId orderId = placeMockOrder(SqrtPrice.wrap(2 << 96), 100, neighborTicks);
        assertEq(SqrtPrice.unwrap(ticks[SqrtPrice.wrap(0)].next), 2 << 96);

        (, BalanceDelta delta) = ticks.removeOrder(orderId);
        // amount 1 = 100, amount 0 = 25
        assertEq(BalanceDelta.unwrap(delta), BalanceDelta.unwrap(toBalanceDelta(25, 0)));
        assertEq(SqrtPrice.unwrap(ticks[SqrtPrice.wrap(0)].next), type(uint160).max);
        assertEq(ticks[SqrtPrice.wrap(100)].totalOpenAmount, 0);
    }

    function test_removeOrder_totalOpenAmount() public {
        SqrtPrice[] memory neighborTicks = new SqrtPrice[](0);
        SqrtPrice targetTick = SqrtPrice.wrap(2 << 96);
        // Remove zeroForOne = true
        OrderLevelLibrary.PlaceOrderParams memory params = OrderLevelLibrary.PlaceOrderParams({
            maker: address(this),
            zeroForOne: true,
            amount: 10 ether,
            targetTick: targetTick,
            currentTick: SqrtPrice.wrap(0),
            neighborTicks: neighborTicks
        });

        OrderId orderId = ticks.placeOrder(params);

        // Change order fill amount
        ticks[targetTick].orders[orderId].amountFilled = 2 ether;

        (, BalanceDelta delta) = ticks.removeOrder(orderId);
        // amount1 = 8 ether, so amount0 = 2 ether
        assertEq(BalanceDelta.unwrap(delta), BalanceDelta.unwrap(toBalanceDelta(2 ether, 2 ether)));
        assertEq(ticks[targetTick].totalOpenAmount, 2 ether);

        // Remove zeroForOne = false
        params.zeroForOne = false;
        orderId = ticks.placeOrder(params);

        // Change order fill amount
        ticks[targetTick].orders[orderId].amountFilled = 2 ether;

        (, delta) = ticks.removeOrder(orderId);
        // amount0 = 8 ether, so amount1 = 32 ether
        assertEq(BalanceDelta.unwrap(delta), BalanceDelta.unwrap(toBalanceDelta(2 ether, 32 ether)));
        assertEq(ticks[targetTick].totalOpenAmount, 4 ether);
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

    // TODO: ExactOut
    function test_fuzz_test_fuzz_fillOrder_full(SqrtPrice targetTick, uint32 amount, uint32 amountDelta, bool zeroForOne) public {
        SqrtPrice[] memory neighborTicks = new SqrtPrice[](0);
        Price price = PriceLibrary.fromSqrtPrice(targetTick);
        vm.assume(uint256(amount) * Price.unwrap(price) < type(uint160).max);

        int128 fillAmount = int128(uint128(amount) + uint128(amountDelta));

        placeMockOrder(targetTick, amount, neighborTicks);

        (int128 amountSpecifiedRemaining, SqrtPrice sqrtPriceNext,) =
            ticks.fillOrder(zeroForOne, targetTick, fillAmount);

        assertEq(uint128(amountSpecifiedRemaining), uint128(amountDelta));
        assertEq(ticks[targetTick].totalOpenAmount, 0);
        assertEq(ticks[targetTick].lastOpenOrderIndex, 1);
        assertEq(ticks[targetTick].lastCloseOrderIndex, 1);

        if (zeroForOne) {
            assertEq(SqrtPrice.unwrap(sqrtPriceNext), 0);
        } else {
            assertEq(SqrtPrice.unwrap(sqrtPriceNext), type(uint160).max);
        }
    }

    // TODO: ExactOut
    function test_fuzz_fillOrder_partOneTick(PlaceMockOrderParams calldata tick, bool zeroForOne) public {
        Price price = PriceLibrary.fromSqrtPrice(tick.targetTick);
        vm.assume(uint256(tick.amount) * Price.unwrap(price) < type(uint160).max);
        vm.assume(tick.amount > 2);

        SqrtPrice[] memory neighborTicks = new SqrtPrice[](0);

        placeMockOrder(tick.targetTick, tick.amount, neighborTicks);

        (int128 amountSpecified,,) = ticks.fillOrder(zeroForOne, tick.targetTick, int128(uint128(tick.amount) - 1));

        assertEq(amountSpecified, 0);
        assertEq(ticks[tick.targetTick].totalOpenAmount, 1);
        assertEq(ticks[tick.targetTick].lastCloseOrderIndex, 0);
    }

    // TODO: ExactOut
    function test_fuzz_fillOrder_partTwoTick(PlaceMockOrderParams calldata tick, uint32 otherAmount, bool zeroForOne) public {
        Price price = PriceLibrary.fromSqrtPrice(tick.targetTick);
        vm.assume(uint256(tick.amount) * Price.unwrap(price) < type(uint160).max);
        vm.assume(tick.amount > 1);
        vm.assume(otherAmount > 1);

        SqrtPrice[] memory neighborTicks = new SqrtPrice[](0);

        placeMockOrder(tick.targetTick, tick.amount, neighborTicks);
        placeMockOrder(tick.targetTick, otherAmount, neighborTicks);

        assertEq(ticks[tick.targetTick].totalOpenAmount, uint128(tick.amount) + uint128(otherAmount));
        (int128 amountSpecified,,) = ticks.fillOrder(zeroForOne, tick.targetTick, int128(uint128(tick.amount) + 1));

        assertEq(amountSpecified, 0);
        assertEq(ticks[tick.targetTick].lastCloseOrderIndex, 1);
        assertEq(ticks[tick.targetTick].totalOpenAmount, uint128(otherAmount) - 1);

        OrderId orderId = OrderIdLibrary.from(tick.targetTick, 1);
        OrderId otherOrderId = OrderIdLibrary.from(tick.targetTick, 2);
        assertEq(ticks[tick.targetTick].orders[orderId].amountFilled, 0);
        assertEq(ticks[tick.targetTick].orders[otherOrderId].amountFilled, 1);
    }
}
