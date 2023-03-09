import { testifyElement; Testify } = "mo:testing/Testify";
import { describe; it; itp; equal; Suite } = "mo:testing/SuiteState";

import Buffer "../src/util/Buffer";
import Trie "../src/MerklePatriciaTrie";
import Option "mo:base/Option";

type Trie = Trie.Trie;
type Buffer = Buffer.Buffer;

type State = {
    var a : Nat;
    var b : Nat;
};

let s = Suite<State>({
    var a = 0;
    var b = 0;
});

s.before(
    func(s : State) {
        s.a := 10;
    },
);

await* s.run([
    describe(
        "simple save and retrieve",
        [
            it(
                "should not crash if given a non-existent root",
                func(s : State) : Bool {
                    let root = switch (Buffer.fromHex("3f4399b08efe68945c1cf90ffe85bbe3ce978959da753f9e649f034015b8817d")) {
                        case (?value) { value };
                        case (null) {
                            return false;
                        };
                    };
                    let trie = Trie.init(root);
                    let value = Trie.get(trie, Buffer.fromText("test"));
                    return Option.isSome(value);
                },
            ),
        ],
    ),
]);
