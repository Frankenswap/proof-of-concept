// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {IPoolManager} from "./interfaces/IPoolManager.sol";
import {Pool} from "./models/Pool.sol";
import {PoolId} from "./models/PoolId.sol";
import {SafeCast} from "./libraries/SafeCast.sol";
import {ERC6909Claims} from "./ERC6909Claims.sol";
import {IUnlockCallback} from "./interfaces/callback/IUnlockCallback.sol";
import {Token, TokenLibrary} from "./models/Token.sol";
import {TokenDelta} from "./libraries/TokenDelta.sol";
import {NonzeroDeltaCount} from "./libraries/NonzeroDeltaCount.sol";
import {TranscationLock} from "./libraries/TranscationLock.sol";

contract PoolManager is IPoolManager, ERC6909Claims {
    using SafeCast for *;
    using TokenDelta for Token;

    mapping(PoolId => Pool) pools;

    modifier onlyWhenTxUnlocked() {
        // TODO: Revert selector
        if (!TranscationLock.isUnlocked()) revert();
        _;
    }

    function unlock(bytes calldata data) external returns (bytes memory result) {
        // TODO: Revert selector
        if (TranscationLock.isUnlocked()) revert();

        result = IUnlockCallback(msg.sender).unlockCallback(data);

        // TODO: Revert selector
        if (NonzeroDeltaCount.read() != 0) revert();
        TranscationLock.lock();
    }

    function clear(Token token, uint256 amount) external onlyWhenTxUnlocked {
        int256 current = token.getDelta(msg.sender);
        int128 amountDelta = amount.toInt128();

        // TODO: Add revert selector
        if (amountDelta != current) revert();

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
