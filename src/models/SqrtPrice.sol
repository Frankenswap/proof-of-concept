// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FullMath} from "../library/FullMath.sol";

/// @dev Represented as Q96.96 fixed point number
type SqrtPrice is uint160;

using {equals as ==, notEquals as !=, greaterThan as >, lessThan as <} for SqrtPrice global;
using SqrtPriceLibrary for SqrtPrice global;

function equals(SqrtPrice sqrtPrice, SqrtPrice other) pure returns (bool) {
    return SqrtPrice.unwrap(sqrtPrice) == SqrtPrice.unwrap(other);
}

function notEquals(SqrtPrice sqrtPrice, SqrtPrice other) pure returns (bool) {
    return SqrtPrice.unwrap(sqrtPrice) != SqrtPrice.unwrap(other);
}

function greaterThan(SqrtPrice sqrtPrice, SqrtPrice other) pure returns (bool) {
    return SqrtPrice.unwrap(sqrtPrice) > SqrtPrice.unwrap(other);
}

function lessThan(SqrtPrice sqrtPrice, SqrtPrice other) pure returns (bool) {
    return SqrtPrice.unwrap(sqrtPrice) < SqrtPrice.unwrap(other);
}

library SqrtPriceLibrary {
    function getAmount0(SqrtPrice sqrtPriceLower, SqrtPrice sqrtPriceUpper, uint128 liquidity, bool roundUp)
        internal
        pure
        returns (uint256 amount0)
    {
        // TODO: check sqrtPriceLower greater than 0

        uint256 numerator1 = uint256(liquidity) << 96;
        uint256 numerator2 = SqrtPrice.unwrap(sqrtPriceUpper) - SqrtPrice.unwrap(sqrtPriceLower);

        if (roundUp) {
            amount0 = FullMath.mulDivUp(numerator1, numerator2, SqrtPrice.unwrap(sqrtPriceUpper));

            assembly ("memory-safe") {
                amount0 := add(div(amount0, sqrtPriceLower), and(gt(mod(amount0, sqrtPriceLower), 0), roundUp))
            }
        } else {
            FullMath.mulDiv(numerator1, numerator2, SqrtPrice.unwrap(sqrtPriceUpper)) / SqrtPrice.unwrap(sqrtPriceLower);
        }
    }

    function getAmount1(SqrtPrice sqrtPriceLower, SqrtPrice sqrtPriceUpper, uint128 liquidity, bool roundUp)
        internal
        pure
        returns (uint256 amount1)
    {
        uint256 numerator = SqrtPrice.unwrap(sqrtPriceUpper) - SqrtPrice.unwrap(sqrtPriceLower);

        amount1 = roundUp ? FullMath.mulDivNUp(liquidity, numerator, 96) : FullMath.mulDivN(liquidity, numerator, 96);
    }
}
