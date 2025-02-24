// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FullMath} from "./FullMath.sol";
import {UnsafeMath} from "./UnsafeMath.sol";
import {SafeCast} from "./SafeCast.sol";
import {SqrtPrice} from "../models/SqrtPrice.sol";

library SqrtPriceMath {
    using SafeCast for uint256;

    function getNextSqrtPriceFromAmount0RoundingUp(SqrtPrice sqrtPrice, uint128 liquidity, uint256 amount, bool add)
        internal
        pure
        returns (SqrtPrice)
    {
        if (amount == 0) return sqrtPrice;
        uint256 numerator1 = uint256(liquidity) << 96;
        uint160 sqrtPriceRaw = SqrtPrice.unwrap(sqrtPrice);

        if (add) {
            // Add token0, price decreases -> p_a
            // p_a = L * sqrtP / (L + amount0 * sqrtP)
            unchecked {
                uint256 product = amount * sqrtPriceRaw;
                if (product / amount == sqrtPriceRaw) {
                    uint256 denominator = numerator1 + product;
                    if (denominator >= numerator1) {
                        return SqrtPrice.wrap(FullMath.mulDivUp(numerator1, sqrtPriceRaw, denominator).toUint160());
                    }
                }
                return SqrtPrice.wrap(
                    UnsafeMath.divRoundingUp(numerator1, (numerator1 / sqrtPriceRaw) + amount).toUint160()
                );
            }
        } else {
            // Remove token0, price increases -> p_b
            // p_b = L * sqrtP / (L - amount0 * sqrtP)
            unchecked {
                uint256 product = amount * sqrtPriceRaw;
                // TODO: check for overflow
                uint256 denominator = numerator1 - product;
                return SqrtPrice.wrap(FullMath.mulDivUp(numerator1, sqrtPriceRaw, denominator).toUint160());
            }
        }
    }

    function getNextSqrtPriceFromAmount1RoundingDown(SqrtPrice sqrtPrice, uint128 liquidity, uint256 amount, bool add)
        internal
        pure
        returns (SqrtPrice)
    {
        uint256 sqrtPriceRaw = SqrtPrice.unwrap(sqrtPrice);
        if (add) {
            // Add token1, price increases -> p_b
            // p_b = sqrtP + amount1 / L
            uint256 quotient = FullMath.mulNDiv(amount, 96, liquidity);

            return SqrtPrice.wrap((sqrtPriceRaw + quotient).toUint160());
        } else {
            // Remove token1, price decreases -> p_a
            // p_a = sqrtP - amount1 / L
            uint256 quotient = FullMath.mulNDivUp(amount, 96, liquidity);
            // TODO: check for overflow
            return SqrtPrice.wrap((sqrtPriceRaw - quotient).toUint160());
        }
    }

    function getNextSqrtPriceFromInput(SqrtPrice sqrtPrice, uint128 liquidity, uint256 amountIn, bool zeroForOne)
        internal
        pure
        returns (SqrtPrice)
    {
        // TODO: check for overflow

        // In exactIn:
        // zeroForOne = true, user gives token0, add = true
        // zeroForOne = false, user gives token1, add = true
        return zeroForOne
            ? getNextSqrtPriceFromAmount0RoundingUp(sqrtPrice, liquidity, amountIn, true) // p_a
            : getNextSqrtPriceFromAmount1RoundingDown(sqrtPrice, liquidity, amountIn, true); // p_b
    }

    function getNextSqrtPriceFromOutput(SqrtPrice sqrtPrice, uint128 liquidity, uint256 amountOut, bool zeroForOne)
        internal
        pure
        returns (SqrtPrice)
    {
        // In exactOut:
        // zeroForOne = true, user receives token1, add = false
        // zeroForOne = false, user receives token0, add = false
        return zeroForOne
            ? getNextSqrtPriceFromAmount1RoundingDown(sqrtPrice, liquidity, amountOut, false) // p_a
            : getNextSqrtPriceFromAmount0RoundingUp(sqrtPrice, liquidity, amountOut, false); // p_b
    }

    function getNextSqrtPriceFromOutput(SqrtPrice sqrtPrice, uint128 liquidity, uint256 amountOut, bool zeroForOne)
        internal
        pure
        returns (SqrtPrice)
    {
        return zeroForOne
            ? getNextSqrtPriceFromAmount1RoundingDown(sqrtPrice, liquidity, amountOut, false)
            : getNextSqrtPriceFromAmount0RoundingUp(sqrtPrice, liquidity, amountOut, false);
    }
}
