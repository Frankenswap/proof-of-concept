// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SqrtPrice} from "../models/SqrtPrice.sol";
import {FullMath} from "./FullMath.sol";
import {SafeCast} from "./SafeCast.sol";

/// @title Liquidity math library
library LiquidityMath {
    using SafeCast for uint256;

    function getAmount0(SqrtPrice sqrtPriceLower, SqrtPrice sqrtPriceUpper, uint128 liquidity, bool roundUp)
        internal
        pure
        returns (uint256 amount0)
    {
        uint256 numerator1 = uint256(liquidity) << 96;
        uint256 numerator2 = SqrtPrice.unwrap(sqrtPriceUpper) - SqrtPrice.unwrap(sqrtPriceLower);

        if (roundUp) {
            amount0 = FullMath.mulDivUp(numerator1, numerator2, SqrtPrice.unwrap(sqrtPriceUpper));

            // TODO: not checking for overflow, but should be impooosible in practice
            assembly ("memory-safe") {
                amount0 := add(div(amount0, sqrtPriceLower), gt(mod(amount0, sqrtPriceLower), 0))
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

    function getLiquidityUpper(SqrtPrice sqrtPrice, SqrtPrice sqrtPriceUpper, uint256 amount0)
        internal
        pure
        returns (uint128 liquidityUpper)
    {
        liquidityUpper = FullMath.mulDivN(
            amount0,
            FullMath.mulDiv(
                SqrtPrice.unwrap(sqrtPrice),
                SqrtPrice.unwrap(sqrtPriceUpper),
                SqrtPrice.unwrap(sqrtPriceUpper) - SqrtPrice.unwrap(sqrtPrice)
            ),
            96
        ).toUint128();
    }

    function getLiquidityLower(SqrtPrice sqrtPrice, SqrtPrice sqrtPriceLower, uint256 amount1)
        internal
        pure
        returns (uint128 liquidityLower)
    {
        liquidityLower =
            FullMath.mulNDiv(amount1, 96, SqrtPrice.unwrap(sqrtPrice) - SqrtPrice.unwrap(sqrtPriceLower)).toUint128();
    }
}
