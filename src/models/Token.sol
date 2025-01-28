// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

type Token is address;

using {lt as <} for Token global;

function lt(Token a, Token b) pure returns (bool) {
    return Token.unwrap(a) < Token.unwrap(b);
}
