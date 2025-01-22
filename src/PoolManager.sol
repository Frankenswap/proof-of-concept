// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {IPoolManager} from "./interfaces/IPoolManager.sol";
import {BalanceDelta} from "./models/BalanceDelta.sol";
import {OrderId} from "./models/OrderId.sol";
import {Pool} from "./models/Pool.sol";
import {PoolId} from "./models/PoolId.sol";
import {PoolKey} from "./models/PoolKey.sol";
import {SqrtPrice} from "./models/SqrtPrice.sol";

/// @title PoolManager
contract PoolManager is IPoolManager {
    mapping(PoolId => Pool) internal pools;

    /// @inheritdoc IPoolManager
    function initialize(PoolKey calldata poolKey, SqrtPrice sqrtPrice)
        external
        returns (PoolId poolId, address liquidityToken)
    {
        // TODO: Implement
    }

    /// @inheritdoc IPoolManager
    function mint(PoolKey calldata poolKey, uint128 amount0, uint128 amount1)
        external
        returns (BalanceDelta balanceDelta, int128 liquidityDelta)
    {
        // TODO: Implement
    }

    /// @inheritdoc IPoolManager
    function burn(PoolKey calldata poolKey, uint128 liquidity)
        external
        returns (BalanceDelta balanceDelta, int128 liquidityDelta)
    {
        // TODO: Implement
    }

    /// @inheritdoc IPoolManager
    function placeOrder(PoolKey calldata poolKey, PlaceOrderParams calldata params)
        external
        returns (OrderId orderId, BalanceDelta balanceDelta)
    {
        // TODO: Implement
    }

    /// @inheritdoc IPoolManager
    function removeOrder(PoolKey calldata poolKey, OrderId orderId) external returns (BalanceDelta balanceDelta) {
        // TODO: Implement
    }
}
