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
            uint256 quotient = FullMath.mulNDiv(amount, 96, liquidity);

            return SqrtPrice.wrap((sqrtPriceRaw + quotient).toUint160());
        } else {
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
        return zeroForOne
            ? getNextSqrtPriceFromAmount0RoundingUp(sqrtPrice, liquidity, amountIn, true)
            : getNextSqrtPriceFromAmount1RoundingDown(sqrtPrice, liquidity, amountIn, true);
    }
}
