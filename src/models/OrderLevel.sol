// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Order} from "./Order.sol";
import {OrderId, OrderIdLibrary} from "./OrderId.sol";
import {SqrtPrice} from "./SqrtPrice.sol";
import {Price, PriceLibrary} from "./Price.sol";
import {BalanceDelta, toBalanceDelta} from "./BalanceDelta.sol";
import {SafeCast} from "../libraries/SafeCast.sol";
import {PoolLibrary} from "./Pool.sol";

struct OrderLevel {
    SqrtPrice prev;
    SqrtPrice next;
    uint128 totalOpenAmount;
    uint64 lastOpenOrderIndex;
    uint64 lastCloseOrderIndex;
    mapping(OrderId => Order) orders;
}

using OrderLevelLibrary for OrderLevel global;

/// @title OrderLevelLibrary
library OrderLevelLibrary {
    using SafeCast for uint128;
    using SafeCast for uint256;

    error OrderLevelAlreadyInitialized();

    function initialize(mapping(SqrtPrice => OrderLevel) storage self) internal {
        require(self[SqrtPrice.wrap(0)].next == SqrtPrice.wrap(0), OrderLevelAlreadyInitialized());
        require(self[SqrtPrice.wrap(type(uint160).max)].next == SqrtPrice.wrap(0), OrderLevelAlreadyInitialized());

        self[SqrtPrice.wrap(0)].next = SqrtPrice.wrap(type(uint160).max);
        self[SqrtPrice.wrap(type(uint160).max)].next = SqrtPrice.wrap(type(uint160).max);
    }

    // TODO: Issues #32
    function placeOrder(mapping(SqrtPrice => OrderLevel) storage self, PoolLibrary.PlaceOrderParams memory params)
        internal
        returns (OrderId orderId, uint256 amountIn, uint256 orderAmount)
    {
        SqrtPrice neighborTick;
        SqrtPrice[] memory neighborTicks = params.neighborTicks;

        assembly ("memory-safe") {
            let len := mload(neighborTicks)

            for { let i := 0 } lt(i, len) { i := add(i, 1) } {
                let readTick := mload(add(add(neighborTicks, 0x20), shl(5, i)))

                mstore(0, readTick)
                mstore(0x20, self.slot)

                let slot := keccak256(0, 0x40)
                let readData := sload(add(slot, 2))

                if gt(shr(128, readData), 0) {
                    neighborTick := readTick

                    break
                }
            }

            if iszero(neighborTick) {
                neighborTick := mload(add(params, 0x80))

                mstore(0, neighborTick)
                mstore(0x20, self.slot)
            }
        }

        SqrtPrice targetTick = params.targetTick;

        if (neighborTick < targetTick) {
            SqrtPrice nextTick = self[neighborTick].next;

            while (nextTick < targetTick) {
                nextTick = self[nextTick].next;
            }

            // If nextTick == targetTick, targetTick is in the tick link, so do nothing
            // If nextTick != targetTick, targetTick is not in the tick link, so update the tick link
            if (nextTick != targetTick) {
                SqrtPrice cachePrevTick = self[nextTick].prev;

                self[cachePrevTick].next = targetTick;
                self[targetTick].next = nextTick;

                self[nextTick].prev = targetTick;
                self[targetTick].prev = cachePrevTick;
            }
        }

        if (neighborTick > targetTick) {
            SqrtPrice prevTick = self[neighborTick].prev;

            while (prevTick > targetTick) {
                prevTick = self[prevTick].prev;
            }

            if (prevTick != targetTick) {
                SqrtPrice cacheNextTick = self[prevTick].next;

                self[prevTick].next = targetTick;
                self[targetTick].next = cacheNextTick;

                self[cacheNextTick].prev = targetTick;
                self[targetTick].prev = prevTick;
            }
        }
        // zero for one | exact input |
        //    true      |    true     | orderAmount = getAmount1Delta(-amount)
        //    true      |    false    | orderAmount = amount
        //    false     |    true     | orderAmount = getAmount0Delta(amount)
        //    false     |    false    | orderAmount = amount
        Price price = PriceLibrary.fromSqrtPrice(params.targetTick);

        if (params.amountSpecified < 0) {
            // exactIn
            amountIn = uint256(uint128(-params.amountSpecified));
            orderAmount = params.zeroForOne ? price.getAmount1Delta(amountIn) : price.getAmount0Delta(amountIn);
        } else {
            // exactOut
            orderAmount = uint256(uint128(params.amountSpecified));
            amountIn = params.zeroForOne ? price.getAmount0DeltaUp(orderAmount) : price.getAmount1DeltaUp(orderAmount);
        }

        self[targetTick].lastOpenOrderIndex += 1;
        self[targetTick].totalOpenAmount += orderAmount.toUint128();

        orderId = OrderIdLibrary.from(params.targetTick, self[targetTick].lastOpenOrderIndex);
        self[targetTick].orders[orderId].initialize(params.maker, params.zeroForOne, orderAmount.toUint128());
    }

    // TODO: Issues #32
    function removeOrder(mapping(SqrtPrice => OrderLevel) storage self, OrderId orderId)
        internal
        returns (address orderMaker, BalanceDelta delta)
    {
        SqrtPrice sqrtPrice = OrderIdLibrary.sqrtPrice(orderId);
        uint64 orderIdIndex = OrderIdLibrary.index(orderId);
        uint64 lastCloseOrderIndex = self[sqrtPrice].lastCloseOrderIndex;

        Order memory order = self[sqrtPrice].orders[orderId];
        orderMaker = order.maker;
        if (orderIdIndex <= lastCloseOrderIndex) {
            delta = order.zeroForOne
                ? toBalanceDelta(0, order.amount.toInt128())
                : toBalanceDelta(order.amount.toInt128(), 0);
        } else {
            // lastOpenOrderIndex and lastCloseOrderIndex does not need to be updated.
            // totalOpenAmount should update
            // If updated totalOpenAmount == 0, should remove the sqrtPrice level in linked list

            Price price = PriceLibrary.fromSqrtPrice(sqrtPrice);
            uint128 orderRemaining = order.amount - order.amountFilled;
            uint128 cacheTotalOpenAmount = self[sqrtPrice].totalOpenAmount - orderRemaining;

            if (cacheTotalOpenAmount == 0) {
                SqrtPrice cachePrevTick = self[sqrtPrice].prev;
                SqrtPrice cacheNextTick = self[sqrtPrice].next;

                self[cachePrevTick].next = cacheNextTick;
                self[cacheNextTick].prev = cachePrevTick;
            }

            self[sqrtPrice].totalOpenAmount = cacheTotalOpenAmount;

            delta = order.zeroForOne
                ? toBalanceDelta(price.getAmount0Delta(orderRemaining).uint256toInt128(), order.amountFilled.toInt128())
                : toBalanceDelta(order.amountFilled.toInt128(), price.getAmount1Delta(orderRemaining).uint256toInt128());
        }

        delete self[OrderIdLibrary.sqrtPrice(orderId)].orders[orderId];
    }

    struct FillCache {
        SqrtPrice prev;
        SqrtPrice next;
        uint128 totalOpenAmount;
        uint64 lastOpenOrderIndex;
        uint64 lastCloseOrderIndex;
    }

    // TODO: Issues #32
    function fillOrder(
        mapping(SqrtPrice => OrderLevel) storage self,
        bool zeroForOne,
        SqrtPrice sqrtPrice,
        int256 amountRemaining
    ) internal returns (SqrtPrice sqrtPriceNext, uint256 amountIn, uint256 amountOut, bool isUpdated) {
        OrderLevel storage level = self[sqrtPrice];
        Price price = PriceLibrary.fromSqrtPrice(sqrtPrice);

        // TODO: Use assmebly to optimize
        FillCache memory cache = FillCache({
            prev: level.prev,
            next: level.next,
            totalOpenAmount: level.totalOpenAmount,
            lastOpenOrderIndex: level.lastOpenOrderIndex,
            lastCloseOrderIndex: level.lastCloseOrderIndex
        });

        // zeroForOne = true, sqrtPriceLimitX96 < currentPrice
        sqrtPriceNext = zeroForOne ? cache.prev : cache.next;

        bool exactIn = amountRemaining < 0;

        // zero for one | exact input |
        //    true      |    true     | exactInAmount = amount
        //    true      |    false    | exactInAmount = getAmount0Delta(-amount)
        //    false     |    true     | exactInAmount = amount
        //    false     |    false    | exactInAmount = getAmount1Delta(-amount)
        if (exactIn) {
            amountIn = uint256(-amountRemaining);
        } else {
            if (zeroForOne) {
                amountIn = price.getAmount0DeltaUp(uint256(amountRemaining));
            } else {
                amountIn = price.getAmount1DeltaUp(uint256(amountRemaining));
            }
        }

        // Fill AmountIn <-> Order Level TotalOpenAmount
        if (amountIn >= cache.totalOpenAmount) {
            isUpdated = true;
            level.totalOpenAmount = 0;
            level.lastCloseOrderIndex = cache.lastOpenOrderIndex;

            self[cache.prev].next = cache.next;
            self[cache.next].prev = cache.prev;

            amountIn = cache.totalOpenAmount;
            amountOut =
                zeroForOne ? price.getAmount1Delta(cache.totalOpenAmount) : price.getAmount0Delta(cache.totalOpenAmount);
        } else {
            isUpdated = false;
            mapping(OrderId => Order) storage orders = level.orders;

            // In exactOut mode, the tokens given by the user will be converted into another token to match the orders
            // in LOB. At this time, due to math errors, the token conversion result may be round down, which will
            // lead to match less orders, which is equivalent to the user filling fewer orders and obtaining more tokens.

            uint128 fillOrderAmount = uint128(amountIn); // Safe, amountIn < totalOpenAmount

            level.totalOpenAmount -= fillOrderAmount;
            for (uint64 i = cache.lastCloseOrderIndex + 1; fillOrderAmount != 0; i++) {
                OrderId order = OrderIdLibrary.from(sqrtPrice, i);

                // TODO: optimize
                uint128 available = orders[order].amount - orders[order].amountFilled;

                if (available < fillOrderAmount) {
                    fillOrderAmount -= available;
                } else {
                    // Fill all amount remaining
                    orders[order].amountFilled += fillOrderAmount;

                    fillOrderAmount = 0;

                    // Update lastCloseOrderIndex
                    if (orders[order].amountFilled == orders[order].amount) {
                        level.lastCloseOrderIndex = order.index();
                    } else {
                        level.lastCloseOrderIndex = order.index() - 1;
                    }
                }
            }

            if (exactIn) {
                if (zeroForOne) {
                    amountOut = price.getAmount1Delta(amountIn);
                } else {
                    amountOut = price.getAmount0Delta(amountIn);
                }
            } else {
                amountOut = uint256(amountRemaining);
            }
        }
    }
}
