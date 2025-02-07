// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {FullMath} from "../../src/library/FullMath.sol";
import {Price, PriceLibrary} from "../../src/models/Price.sol";
import {SqrtPrice} from "../../src/models/SqrtPrice.sol";

contract PriceTest is Test {
    function test_fromSqrtPrice() public pure {
        Price price = PriceLibrary.fromSqrtPrice(SqrtPrice.wrap(1 << 96));
        assertEq(Price.unwrap(price), 1 << 96);

        price = PriceLibrary.fromSqrtPrice(SqrtPrice.wrap(1 << 159));
        assertEq(Price.unwrap(price), 1 << (159 * 2 - 96));
    }

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

    function test_fuzz_getAmount0Delta(uint128 amount1, uint64 priceRaw) public pure {
        vm.assume(amount1 > 1 ether);
        vm.assume(priceRaw != 0);
        vm.assume(uint256(amount1) / priceRaw > 0);
        vm.assume(uint256(amount1) / priceRaw < type(uint128).max >> 1);

        Price price = Price.wrap(uint160(priceRaw) << 96);
        uint256 amount0 = uint256(int256(price.getAmount0Delta(amount1)));

        // If amount1 = 340282366920938463463374607431768211452, priceRaw = 18446744073709551615
        // max error: 18.446744073709551612 ether
        assertApproxEqAbsDecimal(amount1, priceRaw * amount0, 20 ether, 18);
    }

    function test_fuzz_getAmount1Delta(uint128 amount0, uint64 priceRaw) public pure {
        vm.assume(amount0 != 0);
        vm.assume(priceRaw != 0);
        vm.assume(uint256(amount0) * priceRaw < type(uint128).max >> 1);

        Price price = Price.wrap(uint160(priceRaw) << 96);
        uint256 amount1 = uint256(int256(price.getAmount1Delta(amount0)));

        assertEq(amount1 / amount0, priceRaw);
    }

    function test_fullMulNDiv_edge() public pure {
        uint256 d = 2880167108480334364 << 96;
        uint256 result1 = fullMulNDiv(9006692144905288893597737698337016458386369675408024, 96, d);
        uint256 result2 = FullMath.mulDiv(9006692144905288893597737698337016458386369675408024, 2 ** 96, d);
        assertEq(result1, result2);
        assertEq(result2, 3127142212820248285282886819185066);
    }

    function test_fuzz_getAmount0WithAmount1(uint128 amount0, uint64 priceRaw) public pure {
        vm.assume(amount0 != 0);
        vm.assume(priceRaw != 0);
        vm.assume(uint256(amount0) * uint256(priceRaw) < type(uint128).max >> 1);

        Price price = Price.wrap(uint160(priceRaw) << 96);
        uint128 amount1 = uint128(price.getAmount1Delta(amount0));
        // emit log_uint(amount0);
        uint128 amoun0Other = uint128(price.getAmount0Delta(amount1));

        assertApproxEqAbs(uint256(amount0), uint256(amoun0Other), 1);
    }
}
