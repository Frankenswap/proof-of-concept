// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {SqrtPrice, SqrtPriceLibrary} from "../../src/models/SqrtPrice.sol";

contract SqrtPriceTest is Test {
    int32 constant MIN_TICK = SqrtPriceLibrary.MIN_TICK;
    int32 constant MAX_TICK = SqrtPriceLibrary.MAX_TICK;
    uint160 internal constant MAX_SQRT_PRICE = 1461501286290052445479870394709391467910365253204;
    uint160 internal constant MIN_SQRT_PRICE = 4294968328;

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

    function test_fromTick_one() public pure {
        SqrtPrice sqrtPrice = SqrtPriceLibrary.fromTick(0);
        assertEq(SqrtPrice.unwrap(sqrtPrice), 1 << 96);
    }

    function test_fromTick_isValidMaxTick() public pure {
        SqrtPrice sqrtPrice = SqrtPriceLibrary.fromTick(MAX_TICK);
        assertEq(SqrtPrice.unwrap(sqrtPrice), MAX_SQRT_PRICE);
    }

    function test_fromTick_isValidMinTick() public pure {
        SqrtPrice sqrtPrice = SqrtPriceLibrary.fromTick(MIN_TICK);
        assertEq(SqrtPrice.unwrap(sqrtPrice), MIN_SQRT_PRICE);
    }
}
