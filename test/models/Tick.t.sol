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
    Tick public tick;

    function setUp() public {
        ticks[0].initialize(0, type(uint160).max, 1);
        ticks[type(uint160).max].initialize(0, type(uint160).max, 1);
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

    function verfiyLink(uint256 tickNumber) view internal {
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

    function test_fuzz_placeOrder_next(uint96 targetTick, uint32 tickDelta, uint32 otherTickDelta) public {
        uint160[] memory neighborTicks = new uint160[](0);

        uint160 beforeTick = targetTick;
        uint160 mediumTick = uint160(targetTick) + tickDelta;
        uint160 afterTick = uint160(targetTick) + tickDelta + otherTickDelta;

        placeMockOrder(beforeTick, neighborTicks);
        placeMockOrder(mediumTick, neighborTicks);
        placeMockOrder(afterTick, neighborTicks);

        verfiyLink(4);
    }
}
