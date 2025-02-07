// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {IPoolManager} from "./interfaces/IPoolManager.sol";
import {IShareToken} from "./interfaces/IShareToken.sol";
import {BalanceDelta} from "./models/BalanceDelta.sol";
import {OrderId} from "./models/OrderId.sol";
import {Pool} from "./models/Pool.sol";
import {PoolId} from "./models/PoolId.sol";
import {PoolKey} from "./models/PoolKey.sol";
import {SqrtPrice} from "./models/SqrtPrice.sol";
import {ShareToken} from "./ShareToken.sol";

/// @title PoolManager
contract PoolManager is IPoolManager {
    mapping(PoolId => Pool) private _pools;

    modifier validatePoolKey(PoolKey calldata poolKey) {
        poolKey.validate();
        _;
    }

    /// @inheritdoc IPoolManager
    function initialize(PoolKey calldata poolKey, SqrtPrice sqrtPrice)
        external
        validatePoolKey(poolKey)
        returns (PoolId poolId, IShareToken shareToken)
    {
        poolId = poolKey.toId();
        shareToken = new ShareToken{salt: PoolId.unwrap(poolId)}();
        (uint24 rangeRatioLower, uint24 rangeRatioUpper, uint24 thresholdRatioLower, uint24 thresholdRatioUpper) =
            _pools[poolId].initialize(shareToken, sqrtPrice, poolKey.configs);

        emit Initialize(
            poolId,
            poolKey.token0,
            poolKey.token1,
            poolKey.configs,
            shareToken,
            sqrtPrice,
            rangeRatioLower,
            rangeRatioUpper,
            thresholdRatioLower,
            thresholdRatioUpper
        );
    }

    /// @inheritdoc IPoolManager
    function mint(PoolKey calldata poolKey, uint128 amount0, uint128 amount1)
        external
        validatePoolKey(poolKey)
        returns (BalanceDelta balanceDelta, int128 shareDelta)
    {
        // TODO: Implement
    }

    /// @inheritdoc IPoolManager
    function burn(PoolKey calldata poolKey, uint128 share)
        external
        validatePoolKey(poolKey)
        returns (BalanceDelta balanceDelta, int128 shareDelta)
    {
        // TODO: Implement
    }

    /// @inheritdoc IPoolManager
    function placeOrder(PoolKey calldata poolKey, PlaceOrderParams calldata params)
        external
        validatePoolKey(poolKey)
        returns (OrderId orderId, BalanceDelta balanceDelta)
    {
        // TODO: Implement
    }

    /// @inheritdoc IPoolManager
    function removeOrder(PoolKey calldata poolKey, OrderId orderId)
        external
        validatePoolKey(poolKey)
        returns (BalanceDelta balanceDelta)
    {
        // TODO: Implement
    }
}
