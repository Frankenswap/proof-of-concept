// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.28;

import {SqrtPrice} from "./SqrtPrice.sol";
import {SqrtPriceLevel} from "./SqrtPriceLevel.sol";

struct Pool {
    uint128 reserve0;
    uint128 reserve1;
    address liquidityToken;
    SqrtPrice sqrtPrice;
    uint128 marketDepth;
    uint64 thresholdRatioLower;
    uint64 thresholdRatioUpper;
    SqrtPrice bestAsk;
    SqrtPrice bestBid;
    mapping(SqrtPrice => SqrtPriceLevel) sqrtPriceLevels;
}
