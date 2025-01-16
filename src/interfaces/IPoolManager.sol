// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IPoolManager
interface IPoolManager {
    /// @notice Thrown when trascation unlock is called, but the contract is already unlocked
    error AlreadyTxUnlocked();

    /// @notice Thrown when the token is not settled out after the contract is unlocked
    error TokenNotSettled();

    ///@notice Thrown when native currency is passed to a non native settlement
    error NonzeroNativeValue();

    /// @notice Thrown when `clear` is called with an amount that is not exactly equal to the open currency delta.
    error MustClearExactPositiveDelta();
}
