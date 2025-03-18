// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SqrtPrice} from "./SqrtPrice.sol";
import {FullMath} from "../libraries/FullMath.sol";

type SwapFlag is uint8;

using SwapFlagLibrary for SwapFlag global;

library SwapFlagLibrary {
    // TODO: zeroForOne
    function toFlag(SqrtPrice bestPrice, SqrtPrice targetPrice, bool zeroForOne)
        internal
        pure
        returns (SqrtPrice nextPrice, SwapFlag flag)
    {
        if (zeroForOne) {
            // Price Down
            nextPrice = SqrtPrice.wrap(FullMath.max(SqrtPrice.unwrap(bestPrice), SqrtPrice.unwrap(targetPrice)));
        } else {
            nextPrice = SqrtPrice.wrap(FullMath.min(SqrtPrice.unwrap(bestPrice), SqrtPrice.unwrap(targetPrice)));
        }

        // fil order => min price = best price
        // rebalance => min price = threshold price
        // add order => min price = target price
        uint8 rawFlag = 0;
        unchecked {
            if (nextPrice == bestPrice) {
                rawFlag += 1;
            }

            if (nextPrice == targetPrice) {
                rawFlag += 2;
            }
        }

        flag = SwapFlag.wrap(rawFlag);
    }

    function isFilOrderFlag(SwapFlag flag) internal pure returns (bool filOrder) {
        assembly ("memory-safe") {
            filOrder := and(flag, 1)
        }
    }

    function isAddOrderFlag(SwapFlag flag) internal pure returns (bool addOrder) {
        assembly {
            addOrder := and(flag, 2)
        }
    }
}
