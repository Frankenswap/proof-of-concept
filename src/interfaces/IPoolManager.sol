// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IConfigs} from "../interfaces/IConfigs.sol";
import {BalanceDelta} from "../models/BalanceDelta.sol";
import {OrderId} from "../models/OrderId.sol";
import {PoolId} from "../models/PoolId.sol";
import {PoolKey} from "../models/PoolKey.sol";
import {SqrtPrice} from "../models/SqrtPrice.sol";
import {Token} from "../models/Token.sol";

/// @title IPoolManager
interface IPoolManager {
    /// @notice Emitted when a new pool is initialized
    /// @param poolId The pool id
    /// @param token0 The first token
    /// @param token1 The second token
    /// @param configs The pool configs
    /// @param sqrtPrice The initial square root price
    /// @param liquidityToken The liquidity token
    event Initialize(
        PoolId indexed poolId,
        Token indexed token0,
        Token indexed token1,
        IConfigs configs,
        SqrtPrice sqrtPrice,
        address liquidityToken
    );

    /// @notice Emitted when liquidity is minted
    /// @param poolId The pool id
    /// @param sender The sender
    /// @param balanceDelta The balance delta for the sender
    /// @param liquidityDelta The liquidity delta for the sender
    event Mint(PoolId indexed poolId, address indexed sender, BalanceDelta balanceDelta, int128 liquidityDelta);

    /// @notice Emitted when liquidity is burned
    /// @param poolId The pool id
    /// @param sender The sender
    /// @param balanceDelta The balance delta for the sender
    /// @param liquidityDelta The liquidity delta for the sender
    event Burn(PoolId indexed poolId, address indexed sender, BalanceDelta balanceDelta, int128 liquidityDelta);

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
    /// @return poolId The pool id
    /// @return liquidityToken The liquidity token
    function initialize(PoolKey calldata poolKey, SqrtPrice sqrtPrice)
        external
        returns (PoolId poolId, address liquidityToken);

    /// @notice Mints liquidity
    /// @param poolKey The pool key
    /// @param amount0 The desired amount of token0 to provide
    /// @param amount1 The desired amount of token1 to provide
    /// @return balanceDelta The balance delta required
    /// @return liquidityDelta The liquidity delta received
    function mint(PoolKey calldata poolKey, uint128 amount0, uint128 amount1)
        external
        returns (BalanceDelta balanceDelta, int128 liquidityDelta);

    /// @notice Burns liquidity
    /// @param poolKey The pool key
    /// @param liquidity The amount of liquidity to burn
    /// @return balanceDelta The balance delta received
    /// @return liquidityDelta The liquidity delta required
    function burn(PoolKey calldata poolKey, uint128 liquidity)
        external
        returns (BalanceDelta balanceDelta, int128 liquidityDelta);

    // TODO: add price limit, to decide whether use uint32 or SqrtPrice
    // TODO: add neighbor ticks/SqrtPrices that are already in the linked map, to decide whether use uint32 or SqrtPrice
    struct PlaceOrderParams {
        // whether the order token0 for token1 or vice versa
        bool zeroForOne;
        // whether the order can be partially filled
        bool partiallyFillable;
        // whether any amount not immediately filled should become an open order or be refunded
        bool goodTillCancelled;
        // the desired input amount (if negative), or the desired output amount (if positive)
        int128 amountSpecified;
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
