// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IConfigs} from "../interfaces/IConfigs.sol";
import {IShareToken} from "../interfaces/IShareToken.sol";
import {BalanceDelta} from "../models/BalanceDelta.sol";
import {OrderId} from "../models/OrderId.sol";
import {PoolId} from "../models/PoolId.sol";
import {PoolKey} from "../models/PoolKey.sol";
import {SqrtPrice} from "../models/SqrtPrice.sol";
import {Token} from "../models/Token.sol";

/// @title IPoolManager
interface IPoolManager {
    /// @notice Emitted when a new pool is initialized
    /// @param token0 The first token
    /// @param token1 The second token
    /// @param configs The pool configs
    /// @param poolId The pool id
    /// @param shareToken The share token
    /// @param sqrtPrice The initial square root price
    /// @param shares The initial shares
    /// @param balanceDelta The balance delta required
    event Initialize(
        Token indexed token0,
        Token indexed token1,
        IConfigs indexed configs,
        PoolId poolId,
        IShareToken shareToken,
        SqrtPrice sqrtPrice,
        uint128 shares,
        BalanceDelta balanceDelta
    );

    /// @notice Emitted when the reserves of a pool are modified
    /// @param poolId The pool id
    /// @param sender The sender
    /// @param sharesDelta The shares delta
    /// @param balanceDelta The balance delta required or received
    event ModifyReserves(PoolId indexed poolId, address indexed sender, int128 sharesDelta, BalanceDelta balanceDelta);

    // TODO: PlaceOrder event

    /// @notice Emitted when an order is removed
    /// @param poolId The pool id
    /// @param sender The sender
    /// @param orderId The order id
    /// @param balanceDelta The balance delta for the sender
    event RemoveOrder(
        PoolId indexed poolId, address indexed sender, OrderId indexed orderId, BalanceDelta balanceDelta
    );

    /// @notice Initializes a new pool
    /// @param poolKey The pool key
    /// @param sqrtPrice The initial square root price
    /// @param amount0Desired The desired initial amount of token0
    /// @param amount1Desired The desired initial amount of token1
    /// @return poolId The pool id
    /// @return shareToken The share token
    /// @return shares The initial shares
    /// @return balanceDelta The balance delta required
    function initialize(PoolKey calldata poolKey, SqrtPrice sqrtPrice, uint128 amount0Desired, uint128 amount1Desired)
        external
        returns (PoolId poolId, IShareToken shareToken, uint128 shares, BalanceDelta balanceDelta);

    /// @notice Modifies the reserves of a pool
    /// @param poolKey The pool key
    /// @param sharesDelta The shares delta
    /// @return balanceDelta The balance delta required or received
    function modifyReserves(PoolKey calldata poolKey, int128 sharesDelta)
        external
        returns (BalanceDelta balanceDelta);

    struct PlaceOrderParams {
        // whether the order token0 for token1 or vice versa
        bool zeroForOne;
        // whether the order can be partially filled
        bool partiallyFillable;
        // whether any amount not immediately filled should become an open order or be refunded
        bool goodTillCancelled;
        // the desired input amount (if negative), or the desired output amount (if positive)
        int128 amountSpecified;
        int32 tickLimit;
        SqrtPrice[] neighborTicks;
    }

    /// @notice Places an order
    /// @param poolKey The pool key
    /// @param params The order parameters
    /// @return orderId The order id
    /// @return balanceDelta The balance delta required
    function placeOrder(PoolKey calldata poolKey, PlaceOrderParams calldata params)
        external
        returns (OrderId orderId, BalanceDelta balanceDelta);

    /// @notice Removes an order
    /// @param poolKey The pool key
    /// @param orderId The order id
    /// @return balanceDelta The balance delta received
    function removeOrder(PoolKey calldata poolKey, OrderId orderId) external returns (BalanceDelta balanceDelta);
}
