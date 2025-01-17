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
    function toId(PoolKey calldata self) internal pure returns (PoolId poolId) {
        assembly {
            mstore(0, calldataload(add(self, 12)))
            mstore(20, calldataload(add(self, 44)))
            mstore(32, or(shl(192, calldataload(add(self, 32))), calldataload(add(self, 68))))

            poolId := and(keccak256(0, 60), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }
}
