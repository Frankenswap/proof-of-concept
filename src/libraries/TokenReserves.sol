// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {Token} from "../models/Token.sol";

library TokenReserves {
    /// bytes32(uint256(keccak256("TokenReservesOf")) - 1)
    bytes32 constant RESERVES_OF_SLOT = 0xd057b4f99952fd1ae7372a47da3de5d09503f7374c4c5768e23f04697f35364a;
    /// bytes32(uint256(keccak256("Token")) - 1)
    bytes32 constant TOKEN_SLOT = 0x1317f51c845ce3bfb7c268e5337a825f12f3d0af9584c2bbfbf4e64e314eaf72;

    function getSyncedToken() internal view returns (Token token) {
        assembly ("memory-safe") {
            token := tload(TOKEN_SLOT)
        }
    }

    function resetToken() internal {
        assembly ("memory-safe") {
            tstore(TOKEN_SLOT, 0)
        }
    }

    function syncTokenAndReserves(Token token, uint256 value) internal {
        assembly ("memory-safe") {
            tstore(TOKEN_SLOT, and(token, 0xffffffffffffffffffffffffffffffffffffffff))
            tstore(RESERVES_OF_SLOT, value)
        }
    }

    function getSyncedReserves() internal view returns (uint256 value) {
        assembly ("memory-safe") {
            value := tload(RESERVES_OF_SLOT)
        }
    }
}
