// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Order {
    address maker;
    bool zeroForOne;
    // amount = exactOut
    uint128 amount;
    uint128 amountFilled;
}

using OrderLibrary for Order global;

library OrderLibrary {
    function initialize(Order storage self, address maker, bool zeroForOne, uint128 amount) internal {
        self.maker = maker;
        self.zeroForOne = zeroForOne;
        self.amount = amount;
        self.amountFilled = 0;
    }
}
