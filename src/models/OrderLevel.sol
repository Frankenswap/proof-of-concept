// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Order} from "./Order.sol";
import {OrderId, OrderIdLibrary} from "./OrderId.sol";
import {SqrtPrice} from "./SqrtPrice.sol";
import {Price, PriceLibrary} from "./Price.sol";
import {BalanceDelta, toBalanceDelta} from "./BalanceDelta.sol";
import {SafeCast} from "../library/SafeCast.sol";

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

    error OrderLevelAlreadyInitialized();

    function initialize(mapping(SqrtPrice => OrderLevel) storage self) internal {
        require(self[SqrtPrice.wrap(0)].next == SqrtPrice.wrap(0), OrderLevelAlreadyInitialized());
        require(self[SqrtPrice.wrap(type(uint160).max)].next == SqrtPrice.wrap(0), OrderLevelAlreadyInitialized());

        self[SqrtPrice.wrap(0)].next = SqrtPrice.wrap(type(uint160).max);
        self[SqrtPrice.wrap(type(uint160).max)].next = SqrtPrice.wrap(type(uint160).max);
    }

    struct PlaceOrderParams {
        address maker;
        bool zeroForOne;
        uint128 amount;
        SqrtPrice targetTick;
        SqrtPrice currentTick;
        SqrtPrice[] neighborTicks;
    }

    function placeOrder(mapping(SqrtPrice => OrderLevel) storage self, PlaceOrderParams memory params)
        internal
        returns (OrderId orderId)
    {
        SqrtPrice neighborTick;
        SqrtPrice neighborPrev;
        SqrtPrice neighborNext;
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

                    neighborPrev := sload(slot)
                    neighborNext := sload(add(slot, 1))

                    break
                }
            }

            if iszero(neighborTick) {
                neighborTick := mload(add(params, 0x80))

                mstore(0, neighborTick)
                mstore(0x20, self.slot)

                let slot := keccak256(0, 0x40)
                neighborPrev := sload(slot)
                neighborNext := sload(add(slot, 1))
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

        self[targetTick].lastOpenOrderIndex += 1;
        self[targetTick].totalOpenAmount += params.amount;

        orderId = OrderIdLibrary.from(params.targetTick, self[targetTick].lastOpenOrderIndex);
        self[targetTick].orders[orderId].initialize(params.maker, params.zeroForOne, params.amount);
    }

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
                ? toBalanceDelta(price.getAmount0Delta(orderRemaining), order.amountFilled.toInt128())
                : toBalanceDelta(order.amountFilled.toInt128(), price.getAmount1Delta(orderRemaining));
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

    function fillOrder(
        mapping(SqrtPrice => OrderLevel) storage self,
        bool zeroForOne,
        SqrtPrice sqrtPrice,
        int128 amountSpecified
    ) internal returns (int128 amountSpecifiedRemaining, SqrtPrice sqrtPriceNext, BalanceDelta delta) {
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

        bool exactIn = amountSpecified >= 0;

        // zero for one | exact input |
        //    true      |    true     | exactInAmount = amount
        //    true      |    false    | exactInAmount = getAmount0Delta(-amount)
        //    false     |    true     | exactInAmount = amount
        //    false     |    false    | exactInAmount = getAmount1Delta(-amount)
        uint128 amountIn;
        uint128 amountInUp;
        if (exactIn) {
            amountIn = uint128(amountSpecified);
        } else {
            if (zeroForOne) {
                amountIn = uint128(price.getAmount0Delta(uint128(-amountSpecified)));
                amountInUp = uint128(price.getAmount0DeltaUp(uint128(-amountSpecified)));
            } else {
                amountIn = uint128(price.getAmount1Delta(uint128(-amountSpecified)));
                amountInUp = uint128(price.getAmount1DeltaUp(uint128(-amountSpecified)));
            }
        }

        // Fill AmountIn <-> Order Level TotalOpenAmount
        if (amountIn >= cache.totalOpenAmount) {
            level.totalOpenAmount = 0;
            level.lastCloseOrderIndex = cache.lastOpenOrderIndex;

            self[cache.prev].next = cache.next;
            self[cache.next].prev = cache.prev;

            if (zeroForOne) {
                // zeroForOne = true, order totalOpenAmount is amount 0(exactOut)
                int128 token1Output = price.getAmount1Delta(cache.totalOpenAmount);

                delta = toBalanceDelta(-cache.totalOpenAmount.toInt128(), token1Output);

                amountSpecifiedRemaining = amountSpecified < 0
                    ? amountSpecified + token1Output // exactOut, zeroForOne = true, amountSpecified = token 1
                    : (amountIn - cache.totalOpenAmount).toInt128(); // exactIn, zeroForOne = true, amountSpecified = token 0
            } else {
                // zeroForOne = false, order totalOpenAmount is amount 1(exactOut)
                int128 token0Output = price.getAmount0Delta(cache.totalOpenAmount);

                delta = toBalanceDelta(token0Output, -cache.totalOpenAmount.toInt128());

                amountSpecifiedRemaining = amountSpecified < 0
                    ? amountSpecified + token0Output // exactOut, zeroForOne = false, amountSpecified = token 0
                    : (amountIn - cache.totalOpenAmount).toInt128(); // exactIn, zeroForOne = false, amountSpecified = token 1
            }
        } else {
            mapping(OrderId => Order) storage orders = level.orders;

            // In exactOut mode, the tokens given by the user will be converted into another token to match the orders
            // in LOB. At this time, due to math errors, the token conversion result may be round down, which will
            // lead to match less orders, which is equivalent to the user filling fewer orders and obtaining more tokens.

            uint128 amountRemaining = exactIn ? amountIn : amountInUp;

            level.totalOpenAmount -= amountRemaining;
            for (uint64 i = cache.lastCloseOrderIndex + 1; amountRemaining != 0; i++) {
                OrderId order = OrderIdLibrary.from(sqrtPrice, i);

                // TODO: optimize
                uint128 available = orders[order].amount - orders[order].amountFilled;

                if (available < amountRemaining) {
                    amountRemaining -= available;
                } else {
                    // Fill all amount remaining
                    orders[order].amountFilled += amountRemaining;

                    amountRemaining = 0;

                    // Update lastCloseOrderIndex
                    if (orders[order].amountFilled == orders[order].amount) {
                        level.lastCloseOrderIndex = order.index();
                    } else {
                        level.lastCloseOrderIndex = order.index() - 1;
                    }
                }
            }

            if (zeroForOne) {
                // zeroForOne = true, order totalOpenAmount is amount 0(exactOut)
                if (exactIn) {
                    int128 token1Output = price.getAmount1Delta(uint128(amountSpecified));
                    delta = toBalanceDelta(-amountSpecified, token1Output);
                } else {
                    int128 token0Input = price.getAmount0DeltaUp(uint128(-amountSpecified));
                    delta = toBalanceDelta(-token0Input, amountSpecified);
                }
            } else {
                // zeroForOne = false, order totalOpenAmount is amount 1(exactOut)
                if (exactIn) {
                    int128 token0Output = price.getAmount0Delta(uint128(amountSpecified));
                    delta = toBalanceDelta(token0Output, -amountSpecified);
                } else {
                    int128 token1Input = price.getAmount1DeltaUp(uint128(-amountSpecified));
                    delta = toBalanceDelta(amountSpecified, -token1Input);
                }
            }

            amountSpecifiedRemaining = 0;
        }
    }
}
