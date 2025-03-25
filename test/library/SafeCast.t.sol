// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {SafeCast} from "../../src/libraries/SafeCast.sol";

contract SafeCastTest is Test {
    function test_fuzz_abs(int128 x) public pure {
        uint128 y = SafeCast.abs(x);

        if (x >= 0) {
            assertEq(y, uint128(x));
        } else {
            assertEq(y, uint128(uint256(-int256(x))));
        }
    }
}
