// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {PoolId} from "../../src/models/PoolId.sol";
import {PoolKey} from "../../src/models/PoolKey.sol";

contract PoolKeyTest is Test {
    function test_fuzz_toId(PoolKey calldata poolKey) public pure {
        assertEq(
            PoolId.unwrap(poolKey.toId()), keccak256(abi.encodePacked(poolKey.token0, poolKey.token1, poolKey.configs))
        );
    }
}
