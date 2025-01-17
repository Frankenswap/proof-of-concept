// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Layout: 32 tick (uint32) | 160 pool id (PoolId) | 32 index (uint32)
type OrderId is bytes28;
