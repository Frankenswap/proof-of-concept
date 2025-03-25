// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IConfigs} from "../../src/interfaces/IConfigs.sol";
import {SqrtPrice} from "../../src/models/SqrtPrice.sol";
import {Token} from "../../src/models/Token.sol";

contract MockConfig is IConfigs {
    struct ConfigArgs {
        uint24 rangeRatioLower;
        uint24 rangeRatioUpper;
        uint32 minShares;
    }

    mapping(address token0 => mapping(address token1 => ConfigArgs)) public configs;

    function setArgs(address token0, address token1, uint24 rangeRatioLower, uint24 rangeRatioUpper, uint32 minShares)
        public
    {
        configs[token0][token1] =
            ConfigArgs({rangeRatioLower: rangeRatioLower, rangeRatioUpper: rangeRatioUpper, minShares: minShares});
    }

    function initialize(Token token0, Token token1, SqrtPrice)
        external
        view
        override
        returns (uint24 rangeRatioLower, uint24 rangeRatioUpper, uint32 minShares)
    {
        ConfigArgs memory config = configs[Token.unwrap(token0)][Token.unwrap(token1)];

        rangeRatioLower = config.rangeRatioLower;
        rangeRatioUpper = config.rangeRatioUpper;
        minShares = config.minShares;
    }
}
