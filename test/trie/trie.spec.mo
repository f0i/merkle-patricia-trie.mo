import { describe; it; itp; equal; Suite } = "mo:testing/SuiteState";
import T "mo:testing/SuiteState";

import Option "mo:base/Option";

import Buffer "../../src/util/Buffer";
import Trie "../../src/MerklePatriciaTrie";
import Key "../../src/trie/Key";
import Debug "mo:base/Debug";
import Nibble "../../src/util/Nibble";
import Array "mo:base/Array";

module {
    type Trie = Trie.Trie;
    type Path = Trie.Path;
    type Buffer = Buffer.Buffer;
    type Key = Key.Key;
    type Nibble = Nibble.Nibble;

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
                        let expected : Path = {
                            node = #nul;
                            remaining = key;
                            stack = null;
                        };
                        return path == expected;
                    },
                ),

                it(
                    "get existing path with branch",
                    func({}) : Bool {
                        var trie = Trie.init();
                        let key1 = Key.fromKeyBytes([0x12, 0x31]);
                        let key2 = Key.fromKeyBytes([0x22, 0x32]);
                        let key3 = Key.fromKeyBytes([0x32, 0x33]);
                        trie := Trie.put(trie, key1, {});
                        trie := Trie.put(trie, key2, {});
                        trie := Trie.put(trie, key3, {});

                        let path = Trie.findPath(trie, key2, null);
                        let expected : Trie.Node = #leaf {
                            key = Key.slice(key2, 1);
                            value = {};
                            hash = [];
                        };
                        return (path.node == expected);
                    },
                ),

                it(
                    "extension -> branch -> 3 leafs",
                    func({}) : Bool {
                        var trie = Trie.init();
                        let key1 = Key.fromKeyBytes([0x12, 0x31]);
                        let key2 = Key.fromKeyBytes([0x12, 0x32]);
                        let key3 = Key.fromKeyBytes([0x12, 0x33, 0x45]);
                        trie := Trie.put(trie, key1, {});
                        trie := Trie.put(trie, key2, {});
                        trie := Trie.put(trie, key3, {});

                        let path = Trie.findPath(trie, key2, null);
                        let expected : Trie.Node = #leaf {
                            key = [];
                            value = {};
                            hash = [];
                        };
                        //Debug.print(Trie.nodeToText(trie));
                        //Debug.print(Trie.pathToText(path));
                        return (path.node == expected);
                    },
                ),

                it(
                    "Different order should produce the same trie",
                    func({}) : Bool {
                        var keyValuePairs : [(Key, Trie.Value)] = [
                            ([1 : Nibble, 2, 3, 4, 5, 6], {}),
                            ([1 : Nibble, 2, 3, 4, 5], {}),
                            ([1 : Nibble, 2, 3], {}),
                            ([1 : Nibble, 2, 3, 4], {}),
                        ];
                        var trie1 = Trie.init();
                        for ((key, value) in keyValuePairs.vals()) {
                            trie1 := Trie.put(trie1, key, value);
                        };

                        var trie2 = Trie.init();
                        for ((key, value) in Array.reverse(keyValuePairs).vals()) {
                            trie2 := Trie.put(trie2, key, value);
                        };

                        // check if all key are set
                        for ((key, value) in keyValuePairs.vals()) {
                            if (Trie.get(trie1, key) == null) {
                                Debug.print("in trie: " # Trie.nodeToText(trie2));
                                Debug.print("in trie: " # Trie.nodeToText(trie1));
                                Debug.print("key not found: " # Key.toText(key));
                                return false;
                            };
                        };

                        return (trie1 == trie2);
                    },
                ),

                it(
                    "Resinsert shouldn't change the trie",
                    func({}) : Bool {
                        var keyValuePairs : [(Key, Trie.Value)] = [
                            ([1 : Nibble, 2, 3, 4, 5, 6], {}),
                            ([1 : Nibble, 2, 3, 4, 5], {}),
                            ([1 : Nibble, 2, 3], {}),
                            ([1 : Nibble, 2, 3, 4], {}),
                        ];
                        var trie1 = Trie.init();
                        for ((key, value) in keyValuePairs.vals()) {
                            trie1 := Trie.put(trie1, key, value);
                        };

                        var trie2 = Trie.init();

                        // check if all key are set
                        for ((key, value) in keyValuePairs.vals()) {
                            trie2 := Trie.put(trie1, key, value);
                            if (trie1 != trie2) {
                                Debug.print("the trie: " # Trie.nodeToText(trie1));
                                Debug.print(" != trie: " # Trie.nodeToText(trie2));
                                return false;
                            };
                        };

                        return (trie1 == trie2);
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
