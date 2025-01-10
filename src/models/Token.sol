// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20Minimal} from "../interfaces/external/IERC20Minimal.sol";
import {CustomRevert} from "../libraries/CustomRevert.sol";

using {greaterThan as >, lessThan as <, greaterThanOrEqualTo as >=, equals as ==} for Token global;
type Token is address;

using TokenLibrary for Token global;

function equals(Token token, Token other) pure returns (bool) {
    return Token.unwrap(token) == Token.unwrap(other);
}

function greaterThan(Token token, Token other) pure returns (bool) {
    return Token.unwrap(token) > Token.unwrap(other);
}

function lessThan(Token token, Token other) pure returns (bool) {
    return Token.unwrap(token) < Token.unwrap(other);
}

function greaterThanOrEqualTo(Token token, Token other) pure returns (bool) {
    return Token.unwrap(token) >= Token.unwrap(other);
}

/// @title TokenLibrary
library TokenLibrary {
    /// @notice Additional context for ERC-7751 wrapped error when a native transfer fails
    error NativeTransferFailed();

    /// @notice Additional context for ERC-7751 wrapped error when an ERC20 transfer fails
    error ERC20TransferFailed();

    Token public constant ADDRESS_ZERO = Token.wrap(address(0));

    function transfer(Token token, address to, uint256 amount) internal {
        // altered from https://github.com/transmissions11/solmate/blob/44a9963d4c78111f77caa0e65d677b8b46d6f2e6/src/utils/SafeTransferLib.sol
        // modified custom error selectors

        bool success;
        if (token.isAddressZero()) {
            assembly ("memory-safe") {
                // Transfer the ETH and revert if it fails.
                success := call(gas(), to, amount, 0, 0, 0, 0)
            }
            // revert with NativeTransferFailed, containing the bubbled up error as an argument
            if (!success) {
                CustomRevert.bubbleUpAndRevertWith(to, bytes4(0), NativeTransferFailed.selector);
            }
        } else {
            assembly ("memory-safe") {
                let fmp := mload(0x40)

                mstore(fmp, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
                mstore(add(fmp, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
                mstore(add(fmp, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

                success :=
                    and(
                        // Set success to whether the call reverted, if not we check it either
                        // returned exactly 1 (can't just be non-zero data), or had no return data.
                        or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                        // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                        // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                        // Counterintuitively, this call must be positioned second to the or() call in the
                        // surrounding and() call or else returndatasize() will be zero during the computation.
                        call(gas(), token, 0, fmp, 68, 0, 32)
                    )

                // Now clean the memory we used
                mstore(fmp, 0) // 4 byte `selector` and 28 bytes of `to` were stored here
                mstore(add(fmp, 0x20), 0) // 4 bytes of `to` and 28 bytes of `amount` were stored here
                mstore(add(fmp, 0x40), 0) // 4 bytes of `amount` were stored here
            }
            // revert with ERC20TransferFailed, containing the bubbled up error as an argument
            if (!success) {
                CustomRevert.bubbleUpAndRevertWith(
                    Token.unwrap(token), IERC20Minimal.transfer.selector, ERC20TransferFailed.selector
                );
            }
        }
    }

    function balanceOfSelf(Token token) internal view returns (uint256) {
        if (token.isAddressZero()) {
            return address(this).balance;
        } else {
            return IERC20Minimal(Token.unwrap(token)).balanceOf(address(this));
        }
    }

    function balanceOf(Token token, address owner) internal view returns (uint256) {
        if (token.isAddressZero()) {
            return owner.balance;
        } else {
            return IERC20Minimal(Token.unwrap(token)).balanceOf(owner);
        }
    }

    function isAddressZero(Token token) internal pure returns (bool) {
        return Token.unwrap(token) == Token.unwrap(ADDRESS_ZERO);
    }

    function toId(Token token) internal pure returns (uint256) {
        return uint160(Token.unwrap(token));
    }

    // If the upper 12 bytes are non-zero, they will be zero-ed out
    // Therefore, fromId() and toId() are not inverses of each other
    function fromId(uint256 id) internal pure returns (Token) {
        return Token.wrap(address(uint160(id)));
    }
}
