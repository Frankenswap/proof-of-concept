// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {SwapFlag, SwapFlagLibrary} from "../../src/models/SwapFlag.sol";

contract SwapFlagTest is Test {
    function test_SwapFlag() public pure {
        SwapFlag flag = SwapFlag.wrap(uint8(1));
        vm.assertTrue(flag.getFilOrderFlag());
        vm.assertFalse(flag.getRebalanceFlag());
        vm.assertFalse(flag.getAddOrderFlag());

        flag = SwapFlag.wrap(uint8(3));
        vm.assertTrue(flag.getRebalanceFlag());
        vm.assertFalse(flag.getAddOrderFlag());

        flag = SwapFlag.wrap(uint8(4));
        vm.assertTrue(flag.getAddOrderFlag());
    }

    // TODO: 12 tests
    // best price = target price = threshold price => all

    // best price = target price < threshold price => fil order / add order
    // threshold price < best price = target price => rebalance
    // best price = threshold price < target price => fil order / rebalance
    // target price < best price = threshold price => add order
    // target price = threshold price < best price => add order / rebalance
    // best price < target price = threshold price => fil order

    // best price < target price < threshold price => fil order
    // best price < threshold price < target price => fil order
    // target price < best price < threshold price => add order
    // target price < threshold price < best price => add order
    // threshold price < best price < target price => rebalance
    // threshold price < target price < best price => rebalance
}
