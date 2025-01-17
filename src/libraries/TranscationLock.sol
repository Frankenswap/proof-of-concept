// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

library TranscationLock {
    // bytes32(uint256(keccak256("TranscationUnlocked")) - 1)
    bytes32 internal constant IS_UNLOCKED_SLOT = 0xb4699ac1d082a378e8a52f9fc89e80e320fa7baa790480b0513723b1cdc8d3f4;

    function unlock() internal {
        assembly ("memory-safe") {
            // unlock
            tstore(IS_UNLOCKED_SLOT, true)
        }
    }

    function lock() internal {
        assembly ("memory-safe") {
            tstore(IS_UNLOCKED_SLOT, false)
        }
    }

    function isUnlocked() internal view returns (bool unlocked) {
        assembly ("memory-safe") {
            unlocked := tload(IS_UNLOCKED_SLOT)
        }
    }
}
