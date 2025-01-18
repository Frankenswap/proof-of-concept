// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {IPoolManager} from "./interfaces/IPoolManager.sol";
import {BalanceDelta} from "./models/BalanceDelta.sol";
import {OrderId} from "./models/OrderId.sol";
import {Pool} from "./models/Pool.sol";
import {PoolId} from "./models/PoolId.sol";
import {PoolKey} from "./models/PoolKey.sol";

/// @title PoolManager
contract PoolManager is IPoolManager {
    mapping(PoolId => Pool) internal _pools;

    /// @inheritdoc IPoolManager
    function initialize(PoolKey calldata poolKey, InitializeParams calldata params) external returns (PoolId poolId) {
        // TODO: implement
    }

    /// @inheritdoc IPoolManager
    function modifyLiquidity(PoolKey calldata poolKey, int128 liquidityDelta)
        external
        returns (BalanceDelta balanceDelta)
    {
        // TODO: implement
    }

    /// @inheritdoc IPoolManager
    function placeOrder(PoolKey calldata poolKey, PlaceOrderParams calldata params)
        external
        returns (BalanceDelta balanceDelta, OrderId orderId)
    {
        // TODO: implement
    }

    /// @inheritdoc IPoolManager
    function removeOrder(PoolKey calldata poolKey, OrderId orderId) external returns (BalanceDelta balanceDelta) {
        // TODO: implement
    }

    function _getPool(PoolId id) internal view returns (Pool storage) {
        return _pools[id];
    }
}
