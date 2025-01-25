// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {Position, PositionLibrary} from "../../src/models/Position.sol";

contract PositionTest is Test {
    using PositionLibrary for Position;

    function test_fuzz_pack_unpack(
        uint128 liquidity,
        uint32 rangeRatioLower,
        uint32 rangeRatioUpper,
        uint32 thresholdRatioLower,
        uint32 thresholdRatioUpper
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
