// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IShareToken, IERC20Minimal} from "./interfaces/IShareToken.sol";

/// @title ShareToken
contract ShareToken is IShareToken {
    struct Account {
        uint256 balance;
        mapping(address => uint256) allowances;
    }

    error NotPoolManager();

    address private immutable _poolManager;
    uint256 private _totalSupply;
    mapping(address => Account) private _accounts;

    modifier onlyPoolManager() {
        require(msg.sender == _poolManager, NotPoolManager());
        _;
    }

    constructor() {
        _poolManager = msg.sender;
    }

    /// @inheritdoc IERC20Minimal
    function approve(address spender, uint256 amount) external returns (bool) {
        _accounts[msg.sender].allowances[spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /// @inheritdoc IERC20Minimal
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    /// @inheritdoc IERC20Minimal
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 _allowance = _accounts[from].allowances[msg.sender];

        // do not reduce if given unlimited allowance
        if (_allowance != type(uint256).max) {
            _accounts[from].allowances[msg.sender] = _allowance - amount; // underflow desired
        }
        _transfer(from, to, amount);

        return true;
    }

    /// @inheritdoc IERC20Minimal
    function allowance(address owner, address spender) external view returns (uint256) {
        return _accounts[owner].allowances[spender];
    }

    /// @inheritdoc IERC20Minimal
    function balanceOf(address owner) external view returns (uint256) {
        return _accounts[owner].balance;
    }

    /// @inheritdoc IERC20Minimal
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IShareToken
    function mint(address to, uint256 amount) external onlyPoolManager {
        _transfer(address(0), to, amount);
    }

    /// @inheritdoc IShareToken
    function burn(address from, uint256 amount) external onlyPoolManager {
        _transfer(from, address(0), amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        if (from == address(0)) {
            _totalSupply += amount; // overflow desired
        } else {
            _accounts[from].balance -= amount; // underflow desired
        }

        // over/underflow not possible
        unchecked {
            if (to == address(0)) {
                _totalSupply -= amount;
            } else {
                _accounts[to].balance += amount;
            }
        }

        emit Transfer(from, to, amount);
    }
}
