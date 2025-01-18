// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Layout: 160 sqrtPrice (uint160) | 32 empty | 64 index (uint64)
type OrderId is bytes32;
