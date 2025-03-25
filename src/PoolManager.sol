// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {IPoolManager} from "./interfaces/IPoolManager.sol";
import {SafeCast} from "./libraries/SafeCast.sol";
import {ERC6909Claims} from "./ERC6909Claims.sol";
import {IUnlockCallback} from "./interfaces/callback/IUnlockCallback.sol";
import {Token, TokenLibrary} from "./models/Token.sol";
import {TokenDelta} from "./libraries/TokenDelta.sol";
import {TokenReserves} from "./libraries/TokenReserves.sol";
import {NonzeroDeltaCount} from "./libraries/NonzeroDeltaCount.sol";
import {TranscationLock} from "./libraries/TranscationLock.sol";
import {IShareToken} from "./interfaces/IShareToken.sol";
import {BalanceDelta} from "./models/BalanceDelta.sol";
import {OrderId} from "./models/OrderId.sol";
import {Pool, PoolLibrary} from "./models/Pool.sol";
import {PoolId} from "./models/PoolId.sol";
import {PoolKey} from "./models/PoolKey.sol";
import {SqrtPrice, SqrtPriceLibrary} from "./models/SqrtPrice.sol";

/// @title PoolManager
contract PoolManager is IPoolManager, ERC6909Claims {
    using SafeCast for *;
    using TokenDelta for Token;

    mapping(PoolId => Pool) private _pools;

    modifier validatePoolKey(PoolKey calldata poolKey) {
        poolKey.validate();
        _;
    }

    /// @inheritdoc IPoolManager
    function initialize(PoolKey calldata poolKey, SqrtPrice sqrtPrice, uint128 shares)
        external
        validatePoolKey(poolKey)
        returns (PoolId poolId, IShareToken shareToken, BalanceDelta balanceDelta)
    {
        poolId = poolKey.toId();
        (shareToken, balanceDelta) = _pools[poolId].initialize(poolKey, sqrtPrice, shares);

        emit Initialize(
            poolKey.token0, poolKey.token1, poolKey.configs, poolId, shareToken, sqrtPrice, shares, balanceDelta
        );
    }

    modifier onlyWhenTxUnlocked() {
        if (!TranscationLock.isUnlocked()) AlreadyTxUnlocked.selector.revertWith();
        _;
    }

    function unlock(bytes calldata data) external returns (bytes memory result) {
        if (TranscationLock.isUnlocked()) AlreadyTxUnlocked.selector.revertWith();

        result = IUnlockCallback(msg.sender).unlockCallback(data);

        if (NonzeroDeltaCount.read() != 0) TokenNotSettled.selector.revertWith();
        TranscationLock.lock();
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

    function sync(Token token) external {
        if (token.isAddressZero()) {
            TokenReserves.resetToken();
        } else {
            uint256 balance = token.balanceOfSelf();
            TokenReserves.syncTokenAndReserves(token, balance);
        }
    }

    function take(Token token, address to, uint256 amount) external onlyWhenTxUnlocked {
        unchecked {
            _accountDelta(token, -(amount.toInt128()), msg.sender);
            token.transfer(to, amount);
        }
    }

    function settle() external payable onlyWhenTxUnlocked returns (uint256) {
        return _settle(msg.sender);
    }

    function settleFor(address recipient) external payable onlyWhenTxUnlocked returns (uint256) {
        return _settle(recipient);
    }

    function clear(Token token, uint256 amount) external onlyWhenTxUnlocked {
        int256 current = token.getDelta(msg.sender);
        int128 amountDelta = amount.toInt128();

        if (amountDelta != current) MustClearExactPositiveDelta.selector.revertWith();

        unchecked {
            _accountDelta(token, -(amountDelta), msg.sender);
        }
    }

    function mint(address to, uint256 id, uint256 amount) external onlyWhenTxUnlocked {
        unchecked {
            Token token = TokenLibrary.fromId(id);
            _accountDelta(token, -(amount.toInt128()), msg.sender);
            _mint(to, token.toId(), amount);
        }
    }

    function burn(address from, uint256 id, uint256 amount) external onlyWhenTxUnlocked {
        Token token = TokenLibrary.fromId(id);
        _accountDelta(token, amount.toInt128(), from);
        _burnFrom(from, token.toId(), amount);
    }

    function _settle(address recipient) internal returns (uint256 paid) {
        Token token = TokenReserves.getSyncedToken();

        if (token.isAddressZero()) {
            paid = msg.value;
        } else {
            if (msg.value > 0) NonzeroNativeValue.selector.revertWith();

            uint256 reservesBefore = TokenReserves.getSyncedReserves();
            uint256 reservesNow = token.balanceOfSelf();

            paid = reservesNow - reservesBefore;
            TokenReserves.resetToken();
        }

        _accountDelta(token, paid.toInt128(), recipient);
    }

    function _accountDelta(Token token, int128 delta, address target) internal {
        if (delta == 0) return;

        (int256 previous, int256 next) = TokenDelta.applyDelta(token, target, delta);

        if (next == 0) {
            NonzeroDeltaCount.decrement();
        } else if (previous == 0) {
            NonzeroDeltaCount.increment();
        }
    }
}
