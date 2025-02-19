// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SqrtPrice} from "./SqrtPrice.sol";
import {FullMath} from "../library/FullMath.sol";
import {SafeCast} from "../library/SafeCast.sol";

/// @dev Represented as Q160.96 fixed point number
type Price is uint256;

using PriceLibrary for Price global;

library PriceLibrary {
    using SafeCast for uint256;

    /// @dev Price = sqrtPrice * sqrtPrice >> 96 (Q96.96)
    function fromSqrtPrice(SqrtPrice sqrtPrice) internal pure returns (Price price) {
        price = Price.wrap(FullMath.mulDivN(SqrtPrice.unwrap(sqrtPrice), SqrtPrice.unwrap(sqrtPrice), 96));
    }

    // price = y / x = token 1 / token 0
    // token 0 = token 1 / price
    function getAmount0Delta(Price price, uint128 amount1) internal pure returns (int128 amount0) {
        // If amount1 is too small, it will have more error
        // If price is too big, it will have more error
        amount0 = FullMath.mulNDiv(amount1, 96, Price.unwrap(price)).uint256toInt128();
    }

    function getAmount0DeltaUp(Price price, uint128 amount1) internal pure returns (int128 amount0) {
        amount0 = FullMath.mulNDivUp(amount1, 96, Price.unwrap(price)).uint256toInt128();
    }

    // token 1 = token 0 * price
    function getAmount1Delta(Price price, uint128 amount0) internal pure returns (int128 amount1) {
        amount1 = FullMath.mulDivN(Price.unwrap(price), amount0, 96).uint256toInt128();
    }

    function getAmount1DeltaUp(Price price, uint128 amount0) internal pure returns (int128 amount1) {
        amount1 = FullMath.mulDivNUp(Price.unwrap(price), amount0, 96).uint256toInt128();
    }
}
