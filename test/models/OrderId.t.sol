// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test} from "forge-std/Test.sol";
import {OrderId, OrderIdLibrary} from "../../src/models/OrderId.sol";

contract OrderIdTest is Test {
    function test_orderId_constants_masks() public pure {
        assertEq(OrderIdLibrary.MASK_64_BITS, type(uint64).max);
        assertEq(OrderIdLibrary.MASK_160_BITS, type(uint160).max);
    }

    function test_fuzz_orderId_pack_unpack(uint32 tick, uint160 poolId, uint64 index) public pure {
        OrderId orderId = OrderIdLibrary.from(tick, poolId, index);

        assertEq(orderId.tick(), tick);
        assertEq(orderId.poolId(), poolId);
        assertEq(orderId.index(), index);
    }

    function test_fuzz_orderId_next(uint32 tick, uint160 poolId, uint64 index) public pure {
        OrderId orderId = OrderIdLibrary.from(tick, poolId, index);

        unchecked {
            assertEq(orderId.next().index(), orderId.index() + 1);
        }
    }
}
