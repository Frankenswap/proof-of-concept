// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Position, PositionLibrary} from "../../src/models/Position.sol";

contract PositionTest is Test {
    function test_fuzz_position_pack_unpack(
        uint128 liquidity,
        uint24 rangeRatioLower,
        uint24 rangeRatioUpper,
        uint24 thresholdRatioLower,
        uint24 thresholdRatioUpper
    ) public pure {
        Position position =
            PositionLibrary.from(liquidity, rangeRatioLower, rangeRatioUpper, thresholdRatioLower, thresholdRatioUpper);

        assertEq(position.liquidity(), liquidity);
        assertEq(position.rangeRatioLower(), rangeRatioLower);
        assertEq(position.rangeRatioUpper(), rangeRatioUpper);
        assertEq(position.thresholdRatioLower(), thresholdRatioLower);
        assertEq(position.thresholdRatioUpper(), thresholdRatioUpper);
    }
}
