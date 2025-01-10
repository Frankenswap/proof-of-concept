// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Layout: 160 sqrtPriceX96 | 64 order index | 32 empty
type OrderId is bytes32;

using OrderIdLibrary for OrderId global;

/// @title OrderIdLibrary
library OrderIdLibrary {}
