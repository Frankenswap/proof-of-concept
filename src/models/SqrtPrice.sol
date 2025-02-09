// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Represented as Q96.96 fixed point number
type SqrtPrice is uint160;

using {equals as ==, notEquals as !=, greaterThan as >, lessThan as <} for SqrtPrice global;

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
