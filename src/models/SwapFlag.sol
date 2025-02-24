// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SqrtPrice} from "./SqrtPrice.sol";
import {FullMath} from "../library/FullMath.sol";

type SwapFlag is uint8;

using SwapFlagLibrary for SwapFlag global;

library SwapFlagLibrary {
    function toFlag(SqrtPrice bestPrice, SqrtPrice targetPrice, SqrtPrice thresholdRatioPrice)
        internal
        pure
        returns (SqrtPrice minPrice, SwapFlag flag)
    {
        minPrice = SqrtPrice.wrap(
            FullMath.min(
                SqrtPrice.unwrap(bestPrice), SqrtPrice.unwrap(targetPrice), SqrtPrice.unwrap(thresholdRatioPrice)
            )
        );

        // fil order => min price = best price
        // rebalance => min price = threshold price
        // add order => min price = target price
        uint8 rawFlag = 0;
        if (minPrice == bestPrice) {
            rawFlag += 1;
        }

        if (minPrice == targetPrice) {
            rawFlag += 2;
        }

        if (minPrice == thresholdRatioPrice) {
            rawFlag += 4;
        }

        flag = SwapFlag.wrap(rawFlag);
    }

    function getFilOrderFlag(SwapFlag flag) internal pure returns (bool filOrder) {
        assembly {
            filOrder := and(flag, 1)
        }
    }

    function getRebalanceFlag(SwapFlag flag) internal pure returns (bool rebalance) {
        assembly {
            rebalance := and(flag, 2)
        }
    }

    function getAddOrderFlag(SwapFlag flag) internal pure returns (bool addOrder) {
        assembly {
            addOrder := and(flag, 4)
        }
    }
}
