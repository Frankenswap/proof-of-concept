// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoolId} from "../models/PoolId.sol";
import {PoolKey} from "../models/PoolKey.sol";

/// @title IPoolManager
interface IPoolManager {
    struct InitializeParams {
        // the initial squre root price
        uint160 sqrtPriceX96;
        // the initial lower and upper bound for lquidity
        uint160 sqrtPriceLowerX96;
        uint160 sqrtPriceUpperX96;
    }

    /// @notice Initialize the pool
    /// @param poolKey The pool key
    /// @param params The initialize parameters
    /// @return The pool id
    function initialize(PoolKey calldata poolKey, InitializeParams calldata params) external returns (PoolId poolId);

    /// @notice Modify the liquidity of the pool
    /// @param poolKey The pool key
    /// @param liquidityDelta The liquidity delta
    /// @return The balance delta
    function modifyLiquidity(PoolKey calldata poolKey, int128 liquidityDelta)
        external
        returns (BalanceDelta balanceDelta);

    struct TradeParams {
        // whether to trade token0 for token1 or vice versa
        bool zeroForOne;
        // whether to create an order for amount not immediately filled
        bool goodTilCancelled;
        // whether to allow for partial fill
        bool partiallyFillable;
        // the desired input amount (if negative), or the desired output amount (if positive)
        int128 amountSpecified;
        // the square root price at which, if reached, to stop trading
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Trade one token for the other according to the given parameters
    /// @param poolKey The pool key
    /// @param params The trade parameters
    /// @return The balance delta and the order id
    function trade(PoolKey calldata poolKey, TradeParams calldata params)
        external
        returns (BalanceDelta balanceDelta, OrderId orderId);

    /// @notice Cancel an order
    /// @param orderId The order id
    function cancelOrder(OrderId orderId) external;
}
