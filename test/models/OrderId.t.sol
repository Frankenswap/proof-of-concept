// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {OrderId, OrderIdLibrary} from "../../src/models/OrderId.sol";
import {SqrtPrice} from "../../src/models/SqrtPrice.sol";

contract OrderIdTest is Test {
    function test_fuzz_orderId_pack_unpack(SqrtPrice sqrtPrice, uint64 index) public pure {
        OrderId orderId = OrderIdLibrary.from(sqrtPrice, index);

        assertEq(SqrtPrice.unwrap(orderId.sqrtPrice()), SqrtPrice.unwrap(sqrtPrice));
        assertEq(orderId.index(), index);
    }

    function test_fuzz_orderId_next(OrderId orderId) public pure {
        assertEq(orderId.next().index(), orderId.index() + 1);
    }
}
