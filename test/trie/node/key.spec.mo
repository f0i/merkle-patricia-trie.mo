import { describe; it; itp; equal; Suite } = "mo:testing/SuiteState";
import T "mo:testing/SuiteState";

import Nibble "../../../src/util/Nibble";
import Key "../../../src/trie/Key";

module {
    type Key = Key.Key;

    type Nibble = Nibble.Nibble;

    public func tests() : T.NamedTest<{}> {
        describe(
            "Key",
            [
                it(
                    "from Buffer",
                    func({}) : Bool {

                        let arr : [Nat8] = [10, 20, 30, 40];
                        let expected : [Nat8] = [215, 104, 48, 20, 158, 180, 22, 198, 77, 31, 199, 153, 0, 125, 94, 231, 29, 50, 121, 152, 186, 107, 57, 69, 193, 165, 9, 209, 18, 73, 158, 20];
                        switch (Key.fromBuffer(arr)) {
                            case (#ok(expected)) { return true };
                            case (_) { return false };
                        };
                    },
                ),
            ],
        );
    };
};
