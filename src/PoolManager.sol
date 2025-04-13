// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {IPoolManager} from "./interfaces/IPoolManager.sol";
import {IUnlockCallback} from "./interfaces/callback/IUnlockCallback.sol";
import {IShareToken} from "./interfaces/IShareToken.sol";
import {BalanceDelta} from "./models/BalanceDelta.sol";
import {OrderId} from "./models/OrderId.sol";
import {Pool, PoolLibrary} from "./models/Pool.sol";
import {PoolId} from "./models/PoolId.sol";
import {PoolKey} from "./models/PoolKey.sol";
import {SqrtPrice, SqrtPriceLibrary} from "./models/SqrtPrice.sol";
import {Token, TokenLibrary} from "./models/Token.sol";
import {TokenDelta} from "./libraries/TokenDelta.sol";
import {ERC6909Claims} from "./ERC6909Claims.sol";
import {SafeCast} from "./libraries/SafeCast.sol";

/// @title PoolManager
contract PoolManager is IPoolManager, ERC6909Claims {
    using SafeCast for uint256;
    using TokenDelta for Token;

    bool transient unlocked;
    uint256 transient nonzeroDeltaCount;
    Token transient tokenReserve;
    uint256 transient tokenReservesOf;

    mapping(PoolId => Pool) private _pools;

    modifier validatePoolKey(PoolKey calldata poolKey) {
        poolKey.validate();
        _;
    }

    modifier onlyWhenUnlocked() {
        require(unlocked, ManagerLocked());
        _;
    }

    function unlock(bytes calldata data) external returns (bytes memory result) {
        require(!unlocked, AlreadyUnlocked());

        unlocked = true;
        result = IUnlockCallback(msg.sender).unlockCallback(data);

        require(nonzeroDeltaCount == 0, TokenNotSettled());
        unlocked = false; // locking
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

    /// @inheritdoc IPoolManager
    function modifyReserves(PoolKey calldata poolKey, int128 sharesDelta)
        external
        onlyWhenUnlocked
        validatePoolKey(poolKey)
        returns (BalanceDelta balanceDelta)
    {
        PoolId poolId = poolKey.toId();

        balanceDelta = _pools[poolId].modifyReserves(sharesDelta);

        _accountPoolBalanceDelta(poolKey, balanceDelta, msg.sender);

        emit ModifyReserves(poolId, msg.sender, sharesDelta, balanceDelta);
    }

    /// @inheritdoc IPoolManager
    function placeOrder(PoolKey calldata poolKey, PlaceOrderParams calldata params)
        external
        onlyWhenUnlocked
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

        _accountPoolBalanceDelta(poolKey, balanceDelta, msg.sender);
    }

    /// @inheritdoc IPoolManager
    function removeOrder(PoolKey calldata poolKey, OrderId orderId)
        external
        onlyWhenUnlocked
        validatePoolKey(poolKey)
        returns (BalanceDelta balanceDelta)
    {
        address orderMaker;
        PoolId poolId = poolKey.toId();

        (orderMaker, balanceDelta) = _pools[poolId].removeOrder(orderId);

        require(orderMaker == msg.sender, MustOrderMaker());

        _accountPoolBalanceDelta(poolKey, balanceDelta, msg.sender);
    }

    function sync(Token token) external {
        if (token.isAddressZero()) {
            tokenReserve = Token.wrap(address(0));
        } else {
            uint256 balance = token.balanceOfSelf();

            tokenReserve = token;
            tokenReservesOf = balance;
        }
    }

    function take(Token token, address to, uint256 amount) external onlyWhenUnlocked {
        unchecked {
            _accountDelta(token, -(amount.uint256toInt128()), msg.sender);
            token.transfer(to, amount);
        }
    }

    function settle() external payable onlyWhenUnlocked returns (uint256) {
        return _settle(msg.sender);
    }

    function settleFor(address recipient) external payable onlyWhenUnlocked returns (uint256) {
        return _settle(recipient);
    }

    function clear(Token token, uint256 amount) external onlyWhenUnlocked {
        int256 current = token.getDelta(msg.sender);
        int128 amountDelta = amount.uint256toInt128();

        require(amountDelta == current, MustClearExactPositiveDelta());
        unchecked {
            _accountDelta(token, -(amountDelta), msg.sender);
        }
    }

    function mint(address to, uint256 id, uint256 amount) external onlyWhenUnlocked {
        unchecked {
            Token token = TokenLibrary.fromId(id);
            _accountDelta(token, -(amount.uint256toInt128()), msg.sender);
            _mint(to, token.toId(), amount);
        }
    }

    function burn(address from, uint256 id, uint256 amount) external onlyWhenUnlocked {
        Token token = TokenLibrary.fromId(id);
        _accountDelta(token, amount.uint256toInt128(), from);
        _burnFrom(from, token.toId(), amount);
    }

    function _settle(address recipient) internal returns (uint256 paid) {
        Token token = tokenReserve;
        if (token.isAddressZero()) {
            paid = msg.value;
        } else {
            require(msg.value == 0, NonzeroNativeValue());

            uint256 reservesBefore = tokenReservesOf;
            uint256 reservesNow = token.balanceOfSelf();

            paid = reservesNow - reservesBefore;
            tokenReserve = Token.wrap(address(0));
        }

        _accountDelta(token, paid.uint256toInt128(), recipient);
    }

    function _accountPoolBalanceDelta(PoolKey calldata poolKey, BalanceDelta delta, address target) internal {
        _accountDelta(poolKey.token0, delta.amount0(), target);
        _accountDelta(poolKey.token1, delta.amount1(), target);
    }

    function _accountDelta(Token token, int128 delta, address target) internal {
        if (delta == 0) return;

        (int256 previous, int256 next) = TokenDelta.applyDelta(token, target, delta);

        if (next == 0) {
            nonzeroDeltaCount -= 1;
        } else if (previous == 0) {
            nonzeroDeltaCount += 1;
        }
    }
}
