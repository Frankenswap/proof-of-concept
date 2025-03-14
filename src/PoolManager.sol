// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {IPoolManager} from "./interfaces/IPoolManager.sol";
import {IShareToken} from "./interfaces/IShareToken.sol";
import {BalanceDelta} from "./models/BalanceDelta.sol";
import {OrderId} from "./models/OrderId.sol";
import {Pool, PoolLibrary} from "./models/Pool.sol";
import {PoolId} from "./models/PoolId.sol";
import {PoolKey} from "./models/PoolKey.sol";
import {SqrtPrice, SqrtPriceLibrary} from "./models/SqrtPrice.sol";

/// @title PoolManager
contract PoolManager is IPoolManager {
    mapping(PoolId => Pool) private _pools;

    modifier validatePoolKey(PoolKey calldata poolKey) {
        poolKey.validate();
        _;
    }

    /// @inheritdoc IPoolManager
    function initialize(PoolKey calldata poolKey, SqrtPrice sqrtPrice, uint128 amount0Desired, uint128 amount1Desired)
        external
        validatePoolKey(poolKey)
        returns (PoolId poolId, IShareToken shareToken, uint128 shares, BalanceDelta balanceDelta)
    {
        poolId = poolKey.toId();
        (shareToken, shares, balanceDelta) =
            _pools[poolId].initialize(poolKey, sqrtPrice, amount0Desired, amount1Desired);

        emit Initialize(
            poolKey.token0, poolKey.token1, poolKey.configs, poolId, shareToken, sqrtPrice, shares, balanceDelta
        );
    }

    /// @inheritdoc IPoolManager
    function modifyReserves(PoolKey calldata poolKey, int128 sharesDelta)
        external
        validatePoolKey(poolKey)
        returns (BalanceDelta balanceDelta)
    {
        PoolId poolId = poolKey.toId();

        balanceDelta = _pools[poolId].modifyReserves(sharesDelta);

        emit ModifyReserves(poolId, msg.sender, sharesDelta, balanceDelta);
    }

    /// @inheritdoc IPoolManager
    function placeOrder(PoolKey calldata poolKey, PlaceOrderParams calldata params)
        external
        validatePoolKey(poolKey)
        returns (OrderId orderId, BalanceDelta balanceDelta)
    {
        SqrtPrice targetTick = SqrtPriceLibrary.fromTick(params.tickLimit);

        PoolId poolId = poolKey.toId();

        (orderId, balanceDelta) = _pools[poolId].placeOrder(
            params.partiallyFillable,
            params.goodTillCancelled,
            PoolLibrary.PlaceOrderParams({
                maker: msg.sender,
                zeroForOne: params.zeroForOne,
                amountSpecified: params.amountSpecified,
                targetTick: targetTick,
                currentTick: _pools[poolId].sqrtPrice,
                neighborTicks: params.neighborTicks
            })
        );
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
