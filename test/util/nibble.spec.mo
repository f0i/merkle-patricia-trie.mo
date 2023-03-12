import { describe; it; itp; equal; Suite } = "mo:testing/SuiteState";
import T "mo:testing/SuiteState";

import Nibble "../../src/util/Nibble";

module {
    type Nibble = Nibble.Nibble;

    public func tests() : T.NamedTest<{}> {
        describe(
            "Nibbles",
            [
                it(
                    "should be able to convert back and forth to byte arrays",
                    func({}) : Bool {
                        let arr : [Nat8] = [10, 20, 30, 40];
                        let nibbles = Nibble.fromArray(arr);
                        let back = Nibble.toArray(nibbles);
                        return back == arr;
                    },
                ),

                describe(
                    "can be compared",
                    [
                        it(
                            "equal",
                            func({}) : Bool {
                                let arr : [Nat8] = [0x12, 0x34, 0x56];
                                let ref : [Nibble] = [1, 2, 3, 4, 5, 6];
                                let nibbles = Nibble.fromArray(arr);
                                return Nibble.compare(nibbles, ref) == #equal;
                            },
                        ),
                        it(
                            "greater",
                            func({}) : Bool {
                                let arr : [Nat8] = [0x12, 0x34, 0x56];
                                let ref : [Nibble] = [1, 2, 2, 4, 5, 6];
                                let nibbles = Nibble.fromArray(arr);
                                return Nibble.compare(nibbles, ref) == #greater;
                            },
                        ),
                        it(
                            "longer, same prefix",
                            func({}) : Bool {
                                let arr : [Nat8] = [0x12, 0x34, 0x56];
                                let ref : [Nibble] = [1, 2, 2, 4, 5, 6, 7];
                                let nibbles = Nibble.fromArray(arr);
                                return Nibble.compare(nibbles, ref) == #greater;
                            },
                        ),
                        it(
                            "less",
                            func({}) : Bool {
                                let arr : [Nat8] = [0x12, 0x34, 0x56];
                                let ref : [Nibble] = [1, 2, 4, 4, 5, 6];
                                let nibbles = Nibble.fromArray(arr);
                                return Nibble.compare(nibbles, ref) == #less;
                            },
                        ),
                        it(
                            "shorter, same prefix",
                            func({}) : Bool {
                                let arr : [Nat8] = [0x12, 0x34, 0x56];
                                let ref : [Nibble] = [1, 2, 2, 4, 5];
                                let nibbles = Nibble.fromArray(arr);
                                return Nibble.compare(nibbles, ref) == #greater;
                            },
                        ),
                    ],
                ),

                it(
                    "replace high nibble",
                    func({}) : Bool {
                        let byte : Nat8 = 0x56;
                        let nibble : Nibble = 0xA;
                        return Nibble.replaceHigh(byte, nibble) == 0xA6;
                    },
                ),

                describe(
                    "compact encode",
                    [
                        it(
                            "[1,2,3,4,5]",
                            func({}) : Bool {
                                let nibbles : [Nibble] = [1, 2, 3, 4, 5];
                                let encoded = Nibble.compactEncode(nibbles, false);
                                return encoded == [0x11, 0x23, 0x45];
                            },
                        ),

                        it(
                            "[1,2,3,4,5,6]",
                            func({}) : Bool {
                                let nibbles : [Nibble] = [1, 2, 3, 4, 5, 6];
                                let encoded = Nibble.compactEncode(nibbles, false);
                                return encoded == [0x00, 0x12, 0x34, 0x56];
                            },
                        ),
                    ],
                ),
            ],
        );
    };
};
