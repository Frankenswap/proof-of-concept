// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IConfigs} from "../interfaces/IConfigs.sol";
import {PoolId} from "./PoolId.sol";
import {Token} from "./Token.sol";

struct PoolKey {
    Token token0;
    Token token1;
    IConfigs configs;
}

using PoolKeyLibrary for PoolKey global;

/// @title PoolKeyLibrary
library PoolKeyLibrary {
    /// @notice Thrown when token0 is not less than token1
    error TokensEqualOrMisordered();

    /// @notice Thrown when configs contract is not set
    error ConfigsNotSet();

    /// @notice Derive the pool id from the pool key
    /// @param self The pool key
    /// @return poolId The pool id
    function toId(PoolKey calldata self) internal pure returns (PoolId poolId) {
        assembly ("memory-safe") {
            mstore(0, calldataload(add(self, 12)))
            mstore(20, calldataload(add(self, 44)))
            mstore(32, or(shl(192, calldataload(add(self, 32))), calldataload(add(self, 68))))

            poolId := keccak256(0, 60)
        }
    }

    function memToId(PoolKey memory poolKey) internal pure returns (PoolId poolId) {
        assembly ("memory-safe") {
            poolId := keccak256(poolKey, 0x60)
        }
    }

    /// @notice Validate the pool key
    /// @param self The pool key
    function validate(PoolKey memory self) internal pure {
        require(self.token0 < self.token1, TokensEqualOrMisordered());
        require(address(self.configs) != address(0), ConfigsNotSet());
    }
}
