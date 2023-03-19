import { describe; it; itp; equal; Suite } = "mo:testing/SuiteState";
import T "mo:testing/SuiteState";

import { section; test } = "../Test";

import Nibble "../../src/util/Nibble";
import Key "../../src/trie/Key";

module {
    type Nibble = Nibble.Nibble;

    public func tests() {
        section "Nibbles";
        do {
            test "should be able to convert back and forth to byte arrays";
            do {
                let arr : [Nat8] = [10, 20, 30, 40];
                let nibbles = Nibble.fromArray(arr);
                let back = Nibble.toArray(nibbles);
                assert back == arr;
            };

            section "Nibbles can be compared";
            do {

                test "equal";
                do {
                    let arr : [Nat8] = [0x12, 0x34, 0x56];
                    let ref : [Nibble] = [1, 2, 3, 4, 5, 6];
                    let nibbles = Nibble.fromArray(arr);
                    assert Nibble.compare(nibbles, ref) == #equal;
                };

                test "greater";
                do {
                    let arr : [Nat8] = [0x12, 0x34, 0x56];
                    let ref : [Nibble] = [1, 2, 2, 4, 5, 6];
                    let nibbles = Nibble.fromArray(arr);
                    assert Nibble.compare(nibbles, ref) == #greater;
                };

                test "longer, same prefix";
                do {
                    let arr : [Nat8] = [0x12, 0x34, 0x56];
                    let ref : [Nibble] = [1, 2, 2, 4, 5, 6, 7];
                    let nibbles = Nibble.fromArray(arr);
                    assert Nibble.compare(nibbles, ref) == #greater;
                };

                test "less";
                do {
                    let arr : [Nat8] = [0x12, 0x34, 0x56];
                    let ref : [Nibble] = [1, 2, 4, 4, 5, 6];
                    let nibbles = Nibble.fromArray(arr);
                    assert Nibble.compare(nibbles, ref) == #less;
                };

                test "shorter, same prefix";
                do {
                    let arr : [Nat8] = [0x12, 0x34, 0x56];
                    let ref : [Nibble] = [1, 2, 2, 4, 5];
                    let nibbles = Nibble.fromArray(arr);
                    assert Nibble.compare(nibbles, ref) == #greater;
                };
            };

            section "Nibble manipulation";

            test "replace high nibble";
            do {
                let byte : Nat8 = 0x56;
                let nibble : Nibble = 0xA;
                assert Nibble.replaceHigh(byte, nibble) == 0xA6;
            };

        };
    };
};
