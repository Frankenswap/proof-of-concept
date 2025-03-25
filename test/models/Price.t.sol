// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {FullMath} from "../../src/libraries/FullMath.sol";
import {Price, PriceLibrary} from "../../src/models/Price.sol";
import {SqrtPrice} from "../../src/models/SqrtPrice.sol";

contract PriceTest is Test {
    function test_fromSqrtPrice() public pure {
        Price price = PriceLibrary.fromSqrtPrice(SqrtPrice.wrap(1 << 96));
        assertEq(Price.unwrap(price), 1 << 96);

        price = PriceLibrary.fromSqrtPrice(SqrtPrice.wrap(1 << 159));
        assertEq(Price.unwrap(price), 1 << (159 * 2 - 96));
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
