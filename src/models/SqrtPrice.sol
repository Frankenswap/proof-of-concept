// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Represented as Q96.96 fixed point number
type SqrtPrice is uint160;

using {equals as ==, notEquals as !=, greaterThan as >, lessThan as <} for SqrtPrice global;

function equals(SqrtPrice sqrtPrice, SqrtPrice other) pure returns (bool) {
    return SqrtPrice.unwrap(sqrtPrice) == SqrtPrice.unwrap(other);
}

function notEquals(SqrtPrice sqrtPrice, SqrtPrice other) pure returns (bool) {
    return SqrtPrice.unwrap(sqrtPrice) != SqrtPrice.unwrap(other);
}

function greaterThan(SqrtPrice sqrtPrice, SqrtPrice other) pure returns (bool) {
    return SqrtPrice.unwrap(sqrtPrice) > SqrtPrice.unwrap(other);
}

function lessThan(SqrtPrice sqrtPrice, SqrtPrice other) pure returns (bool) {
    return SqrtPrice.unwrap(sqrtPrice) < SqrtPrice.unwrap(other);
}

library SqrtPriceLibrary {
    error InvalidTick(int32 tick);

    int32 internal constant MIN_TICK = -110903604;
    int32 internal constant MAX_TICK = 110903603;
    // c0 = 0.0000014 * 2^96
    // 2^0.0000014 = 1.00000097
    int256 internal constant c0 = 0x177cf44765195f0000000000000000000000000000000;

    function fromTick(int32 tick) internal pure returns (SqrtPrice sqrtPrice) {
        unchecked {
            uint256 absTick;

            assembly ("memory-safe") {
                tick := signextend(3, tick)
                let mask := sar(255, tick)
                absTick := xor(mask, add(mask, tick))
            }

            if (absTick > uint256(int256(MAX_TICK))) revert InvalidTick(tick);

            uint256 price;
            assembly ("memory-safe") {
                price := xor(shl(128, 1), mul(xor(shl(128, 1), 0xfffff79c84993593430be84302e41e86), and(absTick, 0x1)))
            }

            if (absTick & 0x2 != 0) price = (price * 0xffffef390978c9859fbb1c39d85752bf) >> 128;
            if (absTick & 0x4 != 0) price = (price * 0xffffde72140b0c7e6cd5ede6e9658a7e) >> 128;
            if (absTick & 0x8 != 0) price = (price * 0xffffbce42c7bfe7fc5c321ebc29c80d8) >> 128;
            if (absTick & 0x10 != 0) price = (price * 0xffff79c86a8f90bcf0ea91ea968d17a0) >> 128;
            if (absTick & 0x20 != 0) price = (price * 0xfffef3911b7d5dfd23db3955b2254463) >> 128;
            if (absTick & 0x40 != 0) price = (price * 0xfffde72350731a74f7289d4b9d6a8c03) >> 128;
            if (absTick & 0x80 != 0) price = (price * 0xfffbce4b06c312462213e5f44e5448bd) >> 128;
            if (absTick & 0x100 != 0) price = (price * 0xfff79ca7a4d4b5cc754dc491c09a367e) >> 128;
            if (absTick & 0x200 != 0) price = (price * 0xffef3995a5bc934fd772e30f1405a8dd) >> 128;
            if (absTick & 0x400 != 0) price = (price * 0xffde7444b28d1edc70b4d28b92a70335) >> 128;
            if (absTick & 0x800 != 0) price = (price * 0xffbceceeb7a9247bea546d0486616d52) >> 128;
            if (absTick & 0x1000 != 0) price = (price * 0xff79eb706bc9b856505bed8cda29b046) >> 128;
            if (absTick & 0x2000 != 0) price = (price * 0xfef41d1a5f89592f0c011c3f63c8f5ea) >> 128;
            if (absTick & 0x4000 != 0) price = (price * 0xfde95287d329a72807431653d1ce83b2) >> 128;
            if (absTick & 0x8000 != 0) price = (price * 0xfbd701c7cd3a018e78697371e8458311) >> 128;
            if (absTick & 0x10000 != 0) price = (price * 0xf7bf5211ca0da207262485942f0eb194) >> 128;
            if (absTick & 0x20000 != 0) price = (price * 0xefc2bf59e4c135aec35b0212dfd1cd6a) >> 128;
            if (absTick & 0x40000 != 0) price = (price * 0xe08d35706c66b9fad67ed8454da311be) >> 128;
            if (absTick & 0x80000 != 0) price = (price * 0xc4f76b68a6b2ece16679b0a418b946d2) >> 128;
            if (absTick & 0x100000 != 0) price = (price * 0x978bcb98b0444e1fafcf805db494c9ac) >> 128;
            if (absTick & 0x200000 != 0) price = (price * 0x59b63684d9ab80f45630b8dcf730b4f2) >> 128;
            if (absTick & 0x400000 != 0) price = (price * 0x1f703399efdb104acbb0b1a9afca311c) >> 128;
            if (absTick & 0x800000 != 0) price = (price * 0x3dc5dac792f9fc23bd91012f6609d09) >> 128;
            if (absTick & 0x1000000 != 0) price = (price * 0xee7e32d8e2bd8ceadcdd1dd511ed5) >> 128;
            if (absTick & 0x2000000 != 0) price = (price * 0xde2ee4c15d3114ecdd9950e4ae) >> 128;
            if (absTick & 0x4000000 != 0) price = (price * 0xc0d55d565f879dfb68a9) >> 128;

            assembly ("memory-safe") {
                // if (tick > 0) price = type(uint256).max / price;
                if sgt(tick, 0) { price := div(not(0), price) }

                // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
                // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
                // we round up in the division so getTickAtSqrtPrice of the output price is always consistent
                // `sub(shl(32, 1), 1)` is `type(uint32).max`
                // `price + type(uint32).max` will not overflow because `price` fits in 192 bits
                sqrtPrice := shr(32, add(price, sub(shl(32, 1), 1)))
            }
        }
    }
}
