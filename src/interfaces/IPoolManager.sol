// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BalanceDelta} from "../models/BalanceDelta.sol";
import {OrderId} from "../models/OrderId.sol";
import {PoolId} from "../models/PoolId.sol";
import {PoolKey} from "../models/PoolKey.sol";

/// @title IPoolManager
interface IPoolManager {
    struct InitializeParams {
        // the initial square root price of the pool
        uint160 sqrtPriceX96;
        // the initial lower and upper bound of the liquidity
        uint160 sqrtPriceLowerX96;
        uint160 sqrtPriceUpperX96;
    }

    /// @notice Initializes a new pool
    /// @param poolKey The key of the pool
    /// @param params The initial parameters of the pool
    /// @return poolId The id of the pool
    function initialize(PoolKey calldata poolKey, InitializeParams calldata params) external returns (PoolId poolId);

    /// @notice Modifies the liquidity of a pool
    /// @param poolKey The key of the pool
    /// @param liquidityDelta The change in liquidity
    /// @return balanceDelta The change in balances
    function modifyLiquidity(PoolKey calldata poolKey, int128 liquidityDelta)
        external
        returns (BalanceDelta balanceDelta);

    struct PlaceOrderParams {
        // whether the order is token0 for token1 or vice versa
        bool zeroForOne;
        // whether the order can be partially filled
        bool partiallyFillable;
        // whether any amount not immediately filled should become an open order or be refunded
        bool goodTillCancelled;
        // the desired input amount (if negative), or the desired output amount (if positive)
        int128 amountSpecified;
        // the square root price at which to stop filling the order, or place an open order
        uint160 sqrtPriceLimitX96;
        // the surrounding ticks for helping newly active tick to find its place
        uint160[] neighborTicks;
    }

    /// @notice Places an order in the pool
    /// @param poolKey The key of the pool
    /// @param params The parameters of the order
    /// @return balanceDelta The change in balances
    /// @return orderId The id of the order
    function placeOrder(PoolKey calldata poolKey, PlaceOrderParams calldata params)
        external
        returns (BalanceDelta balanceDelta, OrderId orderId);

    /// @notice Removes an order from the pool
    /// @param poolKey The key of the pool
    /// @param orderId The id of the order
    /// @return balanceDelta The change in balances
    function removeOrder(PoolKey calldata poolKey, OrderId orderId) external returns (BalanceDelta balanceDelta);
}
