// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test} from "forge-std/Test.sol";
import {Order, OrderLibrary} from "../../src/models/Order.sol";
import {OrderId, OrderIdLibrary} from "../../src/models/OrderId.sol";

contract OrderTest is Test {
    using OrderLibrary for mapping(OrderId => Order);

    mapping(OrderId => Order) public orders;

    function test_addOrder_removeOrder() public {
        OrderId orderId = OrderIdLibrary.from(1, 2);
        Order memory order = Order({amount: 100, fillAmount: 0, zeroForOne: true, initialized: true});

        orders.add(orderId, order);
        assertEq(orders[orderId].amount, order.amount);
        assertEq(orders[orderId].initialized, true);

        orders.remove(orderId);
        assertEq(orders[orderId].amount, 0);
        assertEq(orders[orderId].initialized, true);
    }

    function setUpOrders(uint128 amount, uint96 count) public {
        for (uint96 i = 0; i < count; i++) {
            OrderId orderId = OrderIdLibrary.from(1, i);
            Order memory order = Order({amount: amount, fillAmount: 0, zeroForOne: true, initialized: true});
            orders.add(orderId, order);
        }
    }

    function test_fillOrder() public {
        setUpOrders(100, 10);

        OrderId startOrderId = OrderIdLibrary.from(1, 0);
        orders.fill(310, startOrderId);

        for (uint96 i = 0; i < 3; i++) {
            OrderId orderId = OrderIdLibrary.from(1, i);

            Order memory order = orders[orderId];
            assertEq(order.fillAmount, 100);
        }

        OrderId endOrderId = OrderIdLibrary.from(1, 3);
        assertEq(orders[endOrderId].fillAmount, 10);
    }

    function test_fillOrder_afterRemove() public {
        setUpOrders(100, 10);
        orders.remove(OrderIdLibrary.from(1, 0));

        OrderId startOrderId = OrderIdLibrary.from(1, 0);
        orders.fill(310, startOrderId);

        for (uint96 i = 1; i < 4; i++) {
            OrderId orderId = OrderIdLibrary.from(1, i);

            Order memory order = orders[orderId];
            assertEq(order.fillAmount, 100);
        }

        OrderId endOrderId = OrderIdLibrary.from(1, 4);
        assertEq(orders[endOrderId].fillAmount, 10);
    }
}
