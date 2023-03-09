import { testifyElement; Testify } = "mo:testing/Testify";
import { describe; it; itp; equal; Suite } = "mo:testing/SuiteState";

import Nibble "../../src/util/Nibble";

type State = {};

let s = Suite<State>({});

await* s.run([
    describe(
        "Nibble",
        [
            it(
                "Convert",
                func(s : State) : Bool {
                    let arr : [Nat8] = [10, 20, 30, 40];
                    let nibbles = Nibble.fromArray(arr);
                    let back = Nibble.toArray(nibbles);
                    return back == arr;
                },
            ),
        ],
    ),
]);
