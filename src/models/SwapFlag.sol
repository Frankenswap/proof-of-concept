// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SqrtPrice} from "./SqrtPrice.sol";
import {FullMath} from "../library/FullMath.sol";

type SwapFlag is uint8;

using SwapFlagLibrary for SwapFlag global;

library SwapFlagLibrary {
    // TODO: zeroForOne
    function toFlag(SqrtPrice bestPrice, SqrtPrice targetPrice, SqrtPrice thresholdRatioPrice, bool zeroForOne)
        internal
        pure
        returns (SqrtPrice nextPrice, SwapFlag flag)
    {
        if (zeroForOne) {
            // Price Down
            nextPrice = SqrtPrice.wrap(
                FullMath.max(
                    SqrtPrice.unwrap(bestPrice), SqrtPrice.unwrap(targetPrice), SqrtPrice.unwrap(thresholdRatioPrice)
                )
            );
        } else {
            nextPrice = SqrtPrice.wrap(
                FullMath.min(
                    SqrtPrice.unwrap(bestPrice), SqrtPrice.unwrap(targetPrice), SqrtPrice.unwrap(thresholdRatioPrice)
                )
            );
        }

        // fil order => min price = best price
        // rebalance => min price = threshold price
        // add order => min price = target price
        uint8 rawFlag = 0;
        unchecked {
            if (nextPrice == bestPrice) {
                rawFlag += 1;
            }

            if (nextPrice == thresholdRatioPrice) {
                rawFlag += 2;
            }

            if (nextPrice == targetPrice) {
                rawFlag += 4;
            }
        }

        flag = SwapFlag.wrap(rawFlag);
    }

    function isFilOrderFlag(SwapFlag flag) internal pure returns (bool filOrder) {
        assembly {
            filOrder := and(flag, 1)
        }
    }

    function isRebalanceFlag(SwapFlag flag) internal pure returns (bool rebalance) {
        assembly {
            rebalance := and(flag, 2)
        }
    }

    function isAddOrderFlag(SwapFlag flag) internal pure returns (bool addOrder) {
        assembly {
            addOrder := and(flag, 4)
        }
    }
}
