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
import {FullMath} from "../src/libraries/FullMath.sol";

contract PoolManageTest is Test {
    MockConfig private config;
    PoolManager private manager;

    uint160 internal constant MAX_SQRT_PRICE = 1353242256787872916161145305865171381865557262336; // 1.07 Fix
    uint160 internal constant MIN_SQRT_PRICE = 4294968328;

    function setUp() public {
        config = new MockConfig();
        manager = new PoolManager();
        config.setArgs(address(0xBEEF1), address(0xBEEF2), 0.93e6, 1.07e6, 1);
    }

    function test_pool_initialize() public {
        SqrtPrice sqrtPrice = SqrtPrice.wrap(2 << 96);
        PoolKey memory poolKey =
            PoolKey({token0: Token.wrap(address(0xBEEF1)), token1: Token.wrap(address(0xBEEF2)), configs: config});

        (,, BalanceDelta balanceDelta) = manager.initialize(poolKey, sqrtPrice, 7142857142857142857);

        assertEq(BalanceDelta.unwrap(balanceDelta), BalanceDelta.unwrap(toBalanceDelta(-233644859813084113, -1 ether)));
    }

    function test_fuzz_pool_initialize(SqrtPrice sqrtPrice, uint128 shares) public {
        sqrtPrice = SqrtPrice.wrap(uint160(bound(SqrtPrice.unwrap(sqrtPrice), MIN_SQRT_PRICE, MAX_SQRT_PRICE)));
        // L < 2 ** 223 / (0.07 * sqrtP)
        shares = uint128(bound(shares, 1, 192571047622504556278911350033275412326452574890386378269140767997952 / SqrtPrice.unwrap(sqrtPrice)));
        // L < 2 ** 31 * sqrtP * 1.07 / 0.07
        shares = uint128(bound(shares, 1, 32825821476 * uint256(SqrtPrice.unwrap(sqrtPrice))));
        
        PoolKey memory poolKey =
            PoolKey({token0: Token.wrap(address(0xBEEF1)), token1: Token.wrap(address(0xBEEF2)), configs: config});

        manager.initialize(poolKey, sqrtPrice, shares);
    }
}
