import { testifyElement; Testify } = "mo:testing/Testify";
import { describe; it; itp; equal; Suite } = "mo:testing/SuiteState";

import Nibble "../../src/util/Nibble";

type Nibble = Nibble.Nibble;

type State = {};

let s = Suite<State>({});

await* s.run([
    describe(
        "Nibbles",
        [
            it(
                "should be able to convert back and forth to byte arrays",
                func(s : State) : Bool {
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
                        func(s : State) : Bool {
                            let arr : [Nat8] = [0x12, 0x34, 0x56];
                            let ref : [Nibble] = [1, 2, 3, 4, 5, 6];
                            let nibbles = Nibble.fromArray(arr);
                            return Nibble.compare(nibbles, ref) == #equal;
                        },
                    ),
                    it(
                        "greater",
                        func(s : State) : Bool {
                            let arr : [Nat8] = [0x12, 0x34, 0x56];
                            let ref : [Nibble] = [1, 2, 2, 4, 5, 6];
                            let nibbles = Nibble.fromArray(arr);
                            return Nibble.compare(nibbles, ref) == #greater;
                        },
                    ),
                    it(
                        "longer, same prefix",
                        func(s : State) : Bool {
                            let arr : [Nat8] = [0x12, 0x34, 0x56];
                            let ref : [Nibble] = [1, 2, 2, 4, 5, 6, 7];
                            let nibbles = Nibble.fromArray(arr);
                            return Nibble.compare(nibbles, ref) == #greater;
                        },
                    ),
                    it(
                        "less",
                        func(s : State) : Bool {
                            let arr : [Nat8] = [0x12, 0x34, 0x56];
                            let ref : [Nibble] = [1, 2, 4, 4, 5, 6];
                            let nibbles = Nibble.fromArray(arr);
                            return Nibble.compare(nibbles, ref) == #less;
                        },
                    ),
                    it(
                        "shorter, same prefix",
                        func(s : State) : Bool {
                            let arr : [Nat8] = [0x12, 0x34, 0x56];
                            let ref : [Nibble] = [1, 2, 2, 4, 5];
                            let nibbles = Nibble.fromArray(arr);
                            return Nibble.compare(nibbles, ref) == #greater;
                        },
                    ),
                ],
            ),
        ],
    ),
]);
