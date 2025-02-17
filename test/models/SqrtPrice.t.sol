// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {SqrtPrice, SqrtPriceLibrary} from "../../src/models/SqrtPrice.sol";
import {console} from "forge-std/console.sol";

contract SqrtPriceTest is Test {
    int32 constant MIN_TICK = SqrtPriceLibrary.MIN_TICK;
    int32 constant MAX_TICK = SqrtPriceLibrary.MAX_TICK;

    /// forge-config: default.allow_internal_expect_revert = true
    function test_fuzz_fromTick_throwsForTooLarge(int32 tick) public {
        if (tick > 0) {
            tick = int32(bound(tick, MAX_TICK + 1, type(int32).max));
        } else {
            tick = int32(bound(tick, type(int32).min, MIN_TICK - 1));
        }
        vm.expectRevert(abi.encodeWithSelector(SqrtPriceLibrary.InvalidTick.selector, tick));
        SqrtPriceLibrary.fromTick(tick);
    }
}
