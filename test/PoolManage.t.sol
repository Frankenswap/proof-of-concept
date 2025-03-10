// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PoolManager} from "../src/PoolManager.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {SqrtPrice, SqrtPriceLibrary} from "../src/models/SqrtPrice.sol";
import {PoolKey} from "../src/models/PoolKey.sol";
import {PoolLibrary} from "../src/models/Pool.sol";
import {MockConfig} from "./utils/Config.sol";
import {Token} from "../src/models/Token.sol";
import {OrderId} from "../src/models/OrderId.sol";
import {BalanceDelta, toBalanceDelta} from "../src/models/BalanceDelta.sol";
import {PoolId} from "../src/models/PoolId.sol";

contract PoolManageTest is Test {
    MockConfig private config;
    PoolManager private manager;

    uint160 internal constant MAX_SQRT_PRICE = 1353242256787872916161145305865171381865557262336; // 1.07 Fix
    uint160 internal constant MIN_SQRT_PRICE = 4294968328;

    function setUp() public {
        config = new MockConfig();
        manager = new PoolManager();
        config.setArgs(address(0xBEEF1), address(0xBEEF2), 0.93e6, 1.07e6, 0.95e6, 1.05e6, 1);
    }

    function test_pool_initialize() public {
        SqrtPrice sqrtPrice = SqrtPrice.wrap(2 << 96);
        PoolKey memory poolKey =
            PoolKey({token0: Token.wrap(address(0xBEEF1)), token1: Token.wrap(address(0xBEEF2)), configs: config});

        (,, uint128 shares, BalanceDelta balanceDelta) = manager.initialize(poolKey, sqrtPrice, 1 ether, 1 ether);

        assertEq(shares, 7142857142857142857);
        assertEq(BalanceDelta.unwrap(balanceDelta), BalanceDelta.unwrap(toBalanceDelta(-233644859813084113, -1 ether)));
    }

    function initializePool() public returns (PoolKey memory poolKey) {
        SqrtPrice sqrtPrice = SqrtPrice.wrap(2 << 96);
        poolKey =
            PoolKey({token0: Token.wrap(address(0xBEEF1)), token1: Token.wrap(address(0xBEEF2)), configs: config});

        manager.initialize(poolKey, sqrtPrice, 1 ether, 1 ether);
    }

    function test_pool_placeOrder_directPlaceOrder() public {
        SqrtPrice[] memory neighborTicks = new SqrtPrice[](0);

        PoolKey memory poolKey = initializePool();
        (OrderId orderId,) = manager.placeOrder(poolKey, IPoolManager.PlaceOrderParams({
            zeroForOne: true,
            partiallyFillable: true,
            goodTillCancelled: true,
            amountSpecified: 1 ether,
            tickLimit: 1500000,
            neighborTicks: neighborTicks
        }));

        assertEq(orderId.index(), 1);
        assertEq(SqrtPrice.unwrap(orderId.sqrtPrice()), 167725958451336328555506520250);
    }

    function test_pool_placeOrder_swap() public {

    }
    function test_fuzz_pool_initialize(SqrtPrice sqrtPrice) public {
        sqrtPrice = SqrtPrice.wrap(uint160(bound(SqrtPrice.unwrap(sqrtPrice), MIN_SQRT_PRICE, MAX_SQRT_PRICE)));

        // To liquidityUpper overflow:
        // amount0Desired * 1.07p / 0.07 sqrtP < type(uint128).max
        // amount0Desired * 16 * sqrtP < type(uint128).max (1.07 / 0.07 = 16)
        // amount0Desired * sqrtP < 2 ** 220

        // To liquidityUpper underflow:
        // amount0Desired * 1.07p / 0.07 sqrtP > 1(2 ** 96)
        // amount0Desired * 16 * sqrtP > 2 ** 96
        // uint256(amount0Desired) * 16 * sqrtP > 2 ** 96
        uint128 amount0Desired = uint128(
            bound(SqrtPrice.unwrap(sqrtPrice), 2 ** 92 / SqrtPrice.unwrap(sqrtPrice), 2 ** 220 / SqrtPrice.unwrap(sqrtPrice))
        ) / 2;

        // To liquidityLower overflow:
        // amount1Desired * 2 ** 96 / 0.07 sqrtP < 2 ** 127
        // amount1Desired < 0.07 * sqrtP * 2 ** 31

        // To liquidityLower underflow:
        // amount1Desired * 2 ** 96 / 0.07 sqrtP > 0
        // amount1Desired > 0.07 * sqrtP
        uint128 amount1Desired = uint128(
            bound(
                type(uint160).max - SqrtPrice.unwrap(sqrtPrice),
                uint256(SqrtPrice.unwrap(sqrtPrice)) * 7 / 100 / 2 ** 96,
                uint256(SqrtPrice.unwrap(sqrtPrice)) * 2 ** 31 * 7 / 100
            )
        ) / 2;

        PoolKey memory poolKey =
            PoolKey({token0: Token.wrap(address(0xBEEF1)), token1: Token.wrap(address(0xBEEF2)), configs: config});

        manager.initialize(poolKey, sqrtPrice, amount0Desired, amount1Desired);
    }
}
