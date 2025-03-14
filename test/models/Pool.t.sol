// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Pool, PoolLibrary} from "../../src/models/Pool.sol";
import {SqrtPrice, SqrtPriceLibrary} from "../../src/models/SqrtPrice.sol";
import {PoolKey} from "../../src/models/PoolKey.sol";
import {MockConfig} from "../utils/Config.sol";
import {Token} from "../../src/models/Token.sol";
import {OrderId} from "../../src/models/OrderId.sol";
import {Price, PriceLibrary} from "../../src/models/Price.sol";
import {FullMath} from "../../src/libraries/FullMath.sol";

contract PoolTest is Test {
    using PoolLibrary for Pool;

    MockConfig private config;
    PoolKey poolKey;
    Pool state;

    function setUp() public {
        config = new MockConfig();
        config.setArgs(address(0xBEEF1), address(0xBEEF2), 0.93e6, 1.07e6, 0.95e6, 1.05e6, 1);

        SqrtPrice sqrtPrice = SqrtPrice.wrap(2 << 96);
        poolKey = PoolKey({token0: Token.wrap(address(0xBEEF1)), token1: Token.wrap(address(0xBEEF2)), configs: config});

        state.initialize(poolKey, sqrtPrice, 7142857142857142857);
    }

    function test_fuzz_placeOrder_directPlaceOrder(int128 amountSpecified) public {
        // When zeroForOne = true and amountSpecified< 0, the order amount is getAmount1Delta
        vm.assume(amountSpecified != -170141183460469231731687303715884105728);
        if (amountSpecified < 0) {
            amountSpecified =
                -int128(uint128(bound(uint256(uint128(-amountSpecified)), 1, 37963657990776414156026597815493853184)));
        }

        SqrtPrice[] memory neighborTicks = new SqrtPrice[](0);
        SqrtPrice targetPrice = SqrtPrice.wrap(167725958451336328555506520250);
        (OrderId orderId,) = state.placeOrder(
            true,
            true,
            poolKey,
            PoolLibrary.PlaceOrderParams({
                maker: msg.sender,
                zeroForOne: true,
                amountSpecified: amountSpecified,
                targetTick: targetPrice,
                currentTick: state.sqrtPrice,
                neighborTicks: neighborTicks
            })
        );

        assertEq(orderId.index(), 1);
        assertEq(SqrtPrice.unwrap(orderId.sqrtPrice()), SqrtPrice.unwrap(targetPrice));

        uint128 orderAmount = state.orderLevels[targetPrice].orders[orderId].amount;

        if (amountSpecified < 0) {
            Price price = PriceLibrary.fromSqrtPrice(targetPrice);
            uint256 targetAmount = FullMath.mulDivN(Price.unwrap(price), uint256(uint128(-amountSpecified)), 96);
            assertEq(orderAmount, targetAmount);
        } else {
            assertEq(orderAmount, uint128(amountSpecified));
        }

        assertEq(SqrtPrice.unwrap(state.bestAsk), SqrtPrice.unwrap(targetPrice));
    }

    function test_placeOrder_OnlySwap(int128 amountSpecified) public {
        // amountIn max 187969924812030076
        // amountOut max 714285714285714285
        vm.assume(amountSpecified != -170141183460469231731687303715884105728);

        if (amountSpecified < 0) {
            amountSpecified = -int128(uint128(bound(uint256(uint128(-amountSpecified)), 1, 187969924812030076)));
        } else {
            amountSpecified = int128(uint128(bound(uint256(uint128(amountSpecified)), 1, 714285714285714285)));
        }

        SqrtPrice[] memory neighborTicks = new SqrtPrice[](0);

        SqrtPrice targetPrice = SqrtPrice.wrap(73682191138265837832276803585);

        (OrderId orderId,) = state.placeOrder(
            true,
            true,
            poolKey,
            PoolLibrary.PlaceOrderParams({
                maker: msg.sender,
                zeroForOne: true,
                amountSpecified: amountSpecified,
                targetTick: targetPrice,
                currentTick: state.sqrtPrice,
                neighborTicks: neighborTicks
            })
        );

        assertEq(OrderId.unwrap(orderId), bytes32(0));
    }

    function test_placeOrder_AddOrder(int128 amountSpecified) public {
        // thresholdRatioPrice = 150533508777102241427733505638
        vm.assume(amountSpecified != -170141183460469231731687303715884105728);
        if (amountSpecified < 0) {
            amountSpecified = -int128(
                uint128(
                    bound(
                        uint256(uint128(-amountSpecified)), 187969924812030076, 42535295865117307932921825928971026432
                    )
                )
            );
        } else {
            amountSpecified = int128(uint128(bound(uint256(uint128(amountSpecified)), 714285714285714285, 2 ** 127)));
        }

        SqrtPrice[] memory neighborTicks = new SqrtPrice[](0);

        SqrtPrice targetPrice = SqrtPrice.wrap(150533508777102241427733505639);

        (OrderId orderId,) = state.placeOrder(
            true,
            true,
            poolKey,
            PoolLibrary.PlaceOrderParams({
                maker: msg.sender,
                zeroForOne: true,
                amountSpecified: amountSpecified,
                targetTick: targetPrice,
                currentTick: state.sqrtPrice,
                neighborTicks: neighborTicks
            })
        );

        assertEq(SqrtPrice.unwrap(orderId.sqrtPrice()), SqrtPrice.unwrap(targetPrice));
    }
}
