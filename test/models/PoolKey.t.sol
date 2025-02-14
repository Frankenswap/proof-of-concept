// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {IConfigs} from "../../src/interfaces/IConfigs.sol";
import {PoolId} from "../../src/models/PoolId.sol";
import {PoolKey, PoolKeyLibrary} from "../../src/models/PoolKey.sol";
import {Token} from "../../src/models/Token.sol";

contract PoolKeyTest is Test {
    function test_fuzz_toId(PoolKey calldata poolKey) public pure {
        assertEq(
            PoolId.unwrap(poolKey.toId()), keccak256(abi.encodePacked(poolKey.token0, poolKey.token1, poolKey.configs))
        );
    }

    function test_fuzz_validPoolKey(Token token0, Token token1, IConfigs configs) public pure {
        vm.assume(Token.unwrap(token0) < Token.unwrap(token1));
        vm.assume(address(configs) != address(0));

        PoolKey memory poolKey = PoolKey(token0, token1, configs);
        poolKey.validate();

        assertTrue(true);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_fuzz_token0EqualsOrGreaterThanToken1(Token token0, Token token1, IConfigs configs) public {
        vm.assume(Token.unwrap(token0) >= Token.unwrap(token1));
        vm.assume(address(configs) != address(0));

        PoolKey memory poolKey = PoolKey(token0, token1, configs);

        vm.expectRevert(PoolKeyLibrary.TokensEqualOrMisordered.selector);
        poolKey.validate();
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_fuzz_configsNotSet(Token token0, Token token1) public {
        vm.assume(Token.unwrap(token0) < Token.unwrap(token1));

        PoolKey memory poolKey = PoolKey(token0, token1, IConfigs(address(0)));

        vm.expectRevert(PoolKeyLibrary.ConfigsNotSet.selector);
        poolKey.validate();
    }
}
