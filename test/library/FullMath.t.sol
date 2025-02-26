// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {FullMath} from "../../src/library/FullMath.sol";

contract FullMathTest is Test {
    function fullMulDivN(uint256 x, uint256 y, uint8 n) internal pure returns (uint256 z) {
        z = FullMath.mulDivN(x, y, n);
    }

    function test_fuzz_fullMulDivN(uint256 x, uint256 y, uint8 n) public view {
        (bool success0, bytes memory result0) =
            address(this).staticcall(abi.encodeWithSignature("fullMulDivN(uint256,uint256,uint8)", x, y, n));

        (bool success1, bytes memory result1) =
            address(this).staticcall(abi.encodeWithSignature("fullMulDiv(uint256,uint256,uint256)", x, y, 1 << n));

        assertEq(success0, success1);
        if (success0) {
            assertEq(abi.decode(result0, (uint256)), abi.decode(result1, (uint256)));
        }
    }

    function fullMulDivNUp(uint256 x, uint256 y, uint8 n) internal pure returns (uint256 z) {
        z = FullMath.mulDivNUp(x, y, n);
    }

    function test_fuzz_fullMulDivNUp(uint256 x, uint256 y, uint8 n) public view {
        (bool success0, bytes memory result0) =
            address(this).staticcall(abi.encodeWithSignature("fullMulDivNUp(uint256,uint256,uint8)", x, y, n));

        (bool success1, bytes memory result1) =
            address(this).staticcall(abi.encodeWithSignature("fullMulDivUp(uint256,uint256,uint256)", x, y, 1 << n));

        assertEq(success0, success1);
        if (success0) {
            assertEq(abi.decode(result0, (uint256)), abi.decode(result1, (uint256)));
        }
    }

    function fullMulNDiv(uint256 x, uint8 n, uint256 d) internal pure returns (uint256 z) {
        z = FullMath.mulNDiv(x, n, d);
    }

    function test_fuzz_fullMulNDiv(uint256 x, uint8 n, uint256 d) public view {
        (bool success0, bytes memory result0) =
            address(this).staticcall(abi.encodeWithSignature("fullMulDiv(uint256,uint256,uint256)", x, 1 << n, d));

        (bool success1, bytes memory result1) =
            address(this).staticcall(abi.encodeWithSignature("fullMulNDiv(uint256,uint8,uint256)", x, n, d));

        assertEq(success0, success1);
        if (success0) {
            assertEq(abi.decode(result0, (uint256)), abi.decode(result1, (uint256)));
        }
    }

    function fullMulNDivUp(uint256 x, uint8 n, uint256 d) internal pure returns (uint256 z) {
        z = FullMath.mulNDivUp(x, n, d);
    }

    function test_fuzz_fullMulNDivUp(uint256 x, uint8 n, uint256 d) public view {
        (bool success0, bytes memory result0) =
            address(this).staticcall(abi.encodeWithSignature("fullMulDivUp(uint256,uint256,uint256)", x, 1 << n, d));

        (bool success1, bytes memory result1) =
            address(this).staticcall(abi.encodeWithSignature("fullMulNDivUp(uint256,uint8,uint256)", x, n, d));

        assertEq(success0, success1);
        if (success0) {
            assertEq(abi.decode(result0, (uint256)), abi.decode(result1, (uint256)));
        }
    }

    function test_fullMulNDiv_edge() public pure {
        uint256 d = 2880167108480334364 << 96;
        uint256 result1 = fullMulNDiv(9006692144905288893597737698337016458386369675408024, 96, d);
        uint256 result2 = FullMath.mulDiv(9006692144905288893597737698337016458386369675408024, 2 ** 96, d);
        assertEq(result1, result2);
        assertEq(result2, 3127142212820248285282886819185066);
    }

    function test_fuzz_min(uint160 x, uint160 y, uint160 z) public pure {
        uint160 minValue = FullMath.min(x, y, z);
        assertLe(minValue, x);
        assertLe(minValue, y);
        assertLe(minValue, z);
    }

    function test_fuzz_max(uint160 x, uint160 y, uint160 z) public pure {
        uint160 maxValue = FullMath.max(x, y, z);
        assertGe(maxValue, x);
        assertGe(maxValue, y);
        assertGe(maxValue, z);
    }
}
