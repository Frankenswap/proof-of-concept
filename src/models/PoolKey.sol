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
        poolId = PoolId.wrap(keccak256(abi.encode(self.token0, self.token1, self.configs)));
    }
}
