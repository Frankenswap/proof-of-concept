// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {IPoolManager} from "./interfaces/IPoolManager.sol";
import {Pool} from "./models/Pool.sol";
import {PoolId} from "./models/PoolId.sol";

contract PoolManager is IPoolManager {
    mapping(PoolId => Pool) pools;
}
