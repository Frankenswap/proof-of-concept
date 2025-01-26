// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Price, PriceLibrary} from "../../src/models/Price.sol";
import {SqrtPrice} from "../../src/models/SqrtPrice.sol";

/// @dev Calculates `floor(x * y / d)` with full precision.
/// Throws if result overflows a uint256 or when `d` is zero.
/// Credit to Remco Bloemen under MIT license: https://2π.com/21/muldiv
function fullMulDiv(uint256 x, uint256 y, uint256 d) pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
        // 512-bit multiply `[p1 p0] = x * y`.
        // Compute the product mod `2**256` and mod `2**256 - 1`
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that `product = p1 * 2**256 + p0`.

        // Temporarily use `z` as `p0` to save gas.
        z := mul(x, y) // Lower 256 bits of `x * y`.
        for {} 1 {} {
            // If overflows.
            if iszero(mul(or(iszero(x), eq(div(z, x), y)), d)) {
                let mm := mulmod(x, y, not(0))
                let p1 := sub(mm, add(z, lt(mm, z))) // Upper 256 bits of `x * y`.

                /*------------------- 512 by 256 division --------------------*/

                // Make division exact by subtracting the remainder from `[p1 p0]`.
                let r := mulmod(x, y, d) // Compute remainder using mulmod.
                let t := and(d, sub(0, d)) // The least significant bit of `d`. `t >= 1`.
                // Make sure `z` is less than `2**256`. Also prevents `d == 0`.
                // Placing the check here seems to give more optimal stack operations.
                if iszero(gt(d, p1)) {
                    mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
                    revert(0x1c, 0x04)
                }
                d := div(d, t) // Divide `d` by `t`, which is a power of two.
                // Invert `d mod 2**256`
                // Now that `d` is an odd number, it has an inverse
                // modulo `2**256` such that `d * inv = 1 mod 2**256`.
                // Compute the inverse by starting with a seed that is correct
                // correct for four bits. That is, `d * inv = 1 mod 2**4`.
                let inv := xor(2, mul(3, d))
                // Now use Newton-Raphson iteration to improve the precision.
                // Thanks to Hensel's lifting lemma, this also works in modular
                // arithmetic, doubling the correct bits in each step.
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
                z :=
                    mul(
                        // Divide [p1 p0] by the factors of two.
                        // Shift in bits from `p1` into `p0`. For this we need
                        // to flip `t` such that it is `2**256 / t`.
                        or(mul(sub(p1, gt(r, z)), add(div(sub(0, t), t), 1)), div(sub(z, r), t)),
                        mul(sub(2, mul(d, inv)), inv) // inverse mod 2**256
                    )
                break
            }
            z := div(z, d)
            break
        }
    }
}

contract PriceTest is Test {
    function test_fromSqrtPrice() public pure {
        Price price = PriceLibrary.fromSqrtPrice(SqrtPrice.wrap(1 << 96));
        assertEq(Price.unwrap(price), 1 << 96);

        price = PriceLibrary.fromSqrtPrice(SqrtPrice.wrap(1 << 159));
        assertEq(Price.unwrap(price), 1 << (159 * 2 - 96));
    }

    function fullMulNDiv (uint256 x, uint8 n, uint256 d) internal pure returns (uint256 z) {
        z = PriceLibrary.fullMulNDiv(x, n, d);
    }

    function test_fuzz_fullMulNDiv(uint256 x, uint256 d) public view {
        (bool success0, bytes memory result0) = address(this).staticcall(
            abi.encodeWithSignature("fullMulDiv(uint256,uint256,uint256)", x, 1 << 96, d)
        );

        (bool success1, bytes memory result1) = address(this).staticcall(
            abi.encodeWithSignature("fullMulNDiv(uint256,uint8,uint256)", x, 96, d)
        );

        assertEq(success0, success1);
        if (success0) {
            assertEq(abi.decode(result0, (uint256)), abi.decode(result1, (uint256)));
        }
    }

    function test_fuzz_getAmount0Delta(uint128 amount1, uint64 priceRaw) public pure {
        vm.assume(amount1 != 0);
        vm.assume(priceRaw != 0);

        Price price = Price.wrap(uint160(priceRaw) << 96);
        uint256 amount0 = price.getAmount0Delta(amount1);

        assertEq(amount0 / amount1, priceRaw);
    }

    function test_fuzz_getAmount1Delta(uint128 amount0, uint64 priceRaw) public {
        vm.assume(amount0 > 1 ether);
        vm.assume(priceRaw != 0);
        vm.assume(uint256(amount0) / priceRaw != 0);

        Price price = Price.wrap(uint160(priceRaw) << 96);
        uint256 amount1 = price.getAmount1Delta(amount0);

        emit log_uint(amount1);
        // If amount0 = 340282366920938463463374607431768211452, priceRaw = 18446744073709551615
        // max error: 18.446744073709551612 ether
        assertApproxEqAbsDecimal(amount0, priceRaw * amount1, 20 ether, 18);
    }
}
