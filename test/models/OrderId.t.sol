// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {OrderId, OrderIdLibrary} from "../../src/models/OrderId.sol";

contract OrderIdTest is Test {
    function test_fuzz_orderId_pack_unpack(uint160 sqrtPriceX96, uint64 index) public pure {
        OrderId orderId = OrderIdLibrary.from(sqrtPriceX96, index);

        assertEq(orderId.sqrtPriceX96(), sqrtPriceX96);
        assertEq(orderId.index(), index);
    }

    function test_fuzz_orderId_next(uint160 sqrtPriceX96, uint64 index) public pure {
        OrderId orderId = OrderIdLibrary.from(sqrtPriceX96, index);

        unchecked {
            assertEq(orderId.next().index(), uint64(orderId.index() + 1));
        }
    }
}
