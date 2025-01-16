// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderId} from "./OrderId.sol";

struct Order {
    // Amount > minimun amount in config
    uint128 amount;
    uint128 fillAmount;
    bool zeroForOne;
    bool initialized;
}

using OrderLibrary for Order global;

library OrderLibrary {
    struct StepComputation {
        OrderId nowOrderId;
        uint128 specificAmount;
        bool initialized;
    }

    function add(mapping(OrderId => Order) storage self, OrderId orderId, Order memory order) internal {
        self[orderId] = order;
    }

    function remove(mapping(OrderId => Order) storage self, OrderId orderId) internal {
        // Remove should be clear token
        self[orderId].amount = 0;
    }

    function fill(mapping(OrderId => Order) storage self, uint128 specificAmount, OrderId startId) internal {
        StepComputation memory step;

        step.specificAmount = specificAmount;
        step.nowOrderId = startId;
        // Maybe start OrderId is not initialized
        step.initialized = true;

        while (!(specificAmount == 0 || step.initialized == false)) {
            Order memory order = self[step.nowOrderId];

            // Check Order initialized
            if (order.initialized == false) {
                step.initialized = false;
            } else {
                // TODO: Optimization
                if (order.amount >= step.specificAmount) {
                    order.fillAmount += step.specificAmount;
                    step.specificAmount = 0;

                    self[step.nowOrderId] = order;
                } else {
                    uint128 amountDelta = order.amount - order.fillAmount;
                    order.fillAmount += amountDelta;
                    step.specificAmount -= amountDelta;

                    self[step.nowOrderId] = order;
                }
            }

            step.nowOrderId = step.nowOrderId.next();
        }
    }
}
