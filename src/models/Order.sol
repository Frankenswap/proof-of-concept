// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Order {
    address maker;
    bool zeroForOne;
    uint128 amount;
    uint128 amountFilled;
}
