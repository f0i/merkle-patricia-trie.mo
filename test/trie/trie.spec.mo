import { describe; it; itp; equal; Suite } = "mo:testing/SuiteState";
import T "mo:testing/SuiteState";

import Option "mo:base/Option";

import Buffer "../../src/util/Buffer";
import Trie "../../src/MerklePatriciaTrie";
import Key "../../src/trie/Key";
import Debug "mo:base/Debug";

module {
    type Trie = Trie.Trie;
    type Buffer = Buffer.Buffer;
    type Key = Key.Key;

    func testKey() : Key {
        switch (Key.fromBuffer([0])) {
            case (#ok key) { key };
            case (_) { Debug.trap("Failed to get key") };
        };
    };

    public func tests() : T.NamedTest<{}> {
        describe(
            "Trie",
            [
                it(
                    "trie is not empty after put",
                    func({}) : Bool {
                        var trie = Trie.init();
                        let key = testKey();
                        let path = Trie.findPath(trie, key, null);
                        trie := Trie.put(trie, key, {});
                        return trie != #nul;
                    },
                ),
                it(
                    "get missing path",
                    func({}) : Bool {
                        let trie = Trie.init();
                        let key = testKey();
                        let path = Trie.findPath(trie, key, null);
                        let expected = {
                            node = #nul;
                            remaining = key;
                            stack = null;
                        };
                        return path == expected;
                    },
                ),

                it(
                    "get existing path",
                    func({}) : Bool {
                        var trie = Trie.init();
                        let key = testKey();
                        trie := Trie.put(trie, key, {});
                        let path = Trie.findPath(trie, key, null);
                        let leaf : Trie.Node = #leaf {
                            key = key;
                            value = {};
                            hash = [];
                        };
                        let expected = {
                            node = leaf;
                            remaining = [];
                            stack = ?(leaf, null);
                        };
                        return path == expected;
                    },
                ),
            ],
        );
    };

    public func testsFromEthereumjs() : T.NamedTest<{}> {
        describe(
            "from ethereumjs",
            [
                describe(
                    "simple save and retrieve",
                    [
                        it(
                            "should not crash if given a non-existent root",
                            func({}) : Bool {
                                let root = switch (Buffer.fromHex("3f4399b08efe68945c1cf90ffe85bbe3ce978959da753f9e649f034015b8817d")) {
                                    case (?value) { value };
                                    case (null) {
                                        return false;
                                    };
                                };
                                let trie = Trie.init();
                                let value = Trie.get(trie, Buffer.fromText("test"));
                                return Option.isNull(value);
                            },
                        ),
                    ],
                ),
            ],
        );
    };
};
