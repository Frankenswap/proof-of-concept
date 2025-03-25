// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IERC20Minimal
interface IERC20Minimal {
    /// @notice Emitted when an approval occurs
    /// @param owner The owner
    /// @param spender The spender
    /// @param amount The amount
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Emitted when a transfer occurs
    /// @param from The sender
    /// @param to The recipient
    /// @param amount The amount
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice Approves the spender to spend the amount
    /// @param spender The spender
    /// @param amount The amount
    /// @return True if successful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers the amount to the recipient
    /// @param to The recipient
    /// @param amount The amount
    /// @return True if successful
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Transfers the amount from the sender to the recipient
    /// @param from The sender
    /// @param to The recipient
    /// @param amount The amount
    /// @return True if successful
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the allowance given to the spender by the owner
    /// @param owner The owner
    /// @param spender The spender
    /// @return The allowance
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Returns the balance of the owner
    /// @param owner The owner
    /// @return The balance
    function balanceOf(address owner) external view returns (uint256);

    /// @notice Returns the total supply of the token
    /// @return The total supply
    function totalSupply() external view returns (uint256);
}
