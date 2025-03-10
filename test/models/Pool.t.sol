// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Pool, PoolLibrary} from "../../src/models/Pool.sol";
import {SqrtPrice, SqrtPriceLibrary} from "../../src/models/SqrtPrice.sol";
import {PoolKey} from "../../src/models/PoolKey.sol";
import {MockConfig} from "../utils/Config.sol";
import {Token} from "../../src/models/Token.sol";

contract PoolTest is Test {
    using PoolLibrary for Pool;

    MockConfig config;
    Pool state;

    function setUp() public {
        config = new MockConfig();
        config.setArgs(
            address(0xBEEF1),
            address(0xBEEF2),
            1.07e6,
            0.93e6,
            1.05e6,
            0.95e6,
            1000
        );
    }

    function test_pool_initialize(
        uint160 sqrtPrice,
        uint128 amount0Desired,
        uint128 amount1Desired
    ) public {
        PoolKey memory key = PoolKey({
            token0: Token.wrap(address(0xBEEF1)),
            token1: Token.wrap(address(0xBEEF2)),
            configs: config
        });
    }
}
