// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SqrtPrice} from "../models/SqrtPrice.sol";
import {FullMath} from "./FullMath.sol";

/// @title Liquidity math library
library LiquidityMath {
    function getAmount0(SqrtPrice sqrtPriceLower, SqrtPrice sqrtPriceUpper, uint128 liquidity, bool roundUp)
        internal
        pure
        returns (uint256 amount0)
    {
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

    function getLiquidityUpper(SqrtPrice sqrtPrice, SqrtPrice sqrtPriceUpper, uint256 amount0)
        internal
        pure
        returns (uint128 liquidityUpper)
    {
        // TODO: implement
        // liquidityUpper = amount0 * (sqrtPrice * sqrtPriceUpper) / (sqrtPriceUpper - sqrtPrice)
    }

    function getLiquidityLower(SqrtPrice sqrtPrice, SqrtPrice sqrtPriceLower, uint256 amount1)
        internal
        pure
        returns (uint128 liquidityLower)
    {
        // TODO: implement
        // liquidityLower = amount1 / (sqrtPrice - sqrtPriceLower)
    }
}
