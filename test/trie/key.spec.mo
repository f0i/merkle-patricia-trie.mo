import { section; test } = "../Test";

import Nibble "../../src/util/Nibble";
import Key "../../src/Key";
import Debug "mo:base/Debug";

module {
    type Key = Key.Key;

    type Nibble = Nibble.Nibble;

    public func tests() {
        section "Key";
        do {

            test "drop";
            do {

                let arr : [Nat8] = [0x10, 0x20, 0x30, 0x40];
                let key = Key.fromKeyBytes(arr);
                assert Key.drop(key, 6) == [4, 0];
            };

            test "take";
            do {

                let arr : [Nat8] = [0x10, 0x20, 0x30, 0x40];
                let key = Key.fromKeyBytes(arr);
                assert Key.take(key, 3) == [1, 0, 2];
            };

            section "compact encode";
            do {

                test "[1,2,3,4,5]";
                do {
                    let nibbles : [Nibble] = [1, 2, 3, 4, 5];
                    let encoded = Key.compactEncode(nibbles, false);
                    assert encoded == [0x11, 0x23, 0x45];
                };

                test "[1,2,3,4,5,6]";
                do {
                    let nibbles : [Nibble] = [1, 2, 3, 4, 5, 6];
                    let encoded = Key.compactEncode(nibbles, false);
                    assert encoded == [0x00, 0x12, 0x34, 0x56];
                };
            };
        };
    };
};
