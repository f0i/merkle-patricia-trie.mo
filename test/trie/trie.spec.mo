import { describe; it; itp; equal; Suite } = "mo:testing/SuiteState";
import T "mo:testing/SuiteState";

import Option "mo:base/Option";

import Buffer "../../src/util/Buffer";
import Trie "../../src/MerklePatriciaTrie";
import Key "../../src/trie/Key";
import Debug "mo:base/Debug";
import Nibble "../../src/util/Nibble";
import Array "mo:base/Array";
import Value "../../src/util/Value";

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
                        trie := Trie.put(trie, key, []);
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
                        trie := Trie.put(trie, key1, []);
                        trie := Trie.put(trie, key2, []);
                        trie := Trie.put(trie, key3, []);

                        let path = Trie.findPath(trie, key2, null);
                        let expected : Trie.Node = #leaf {
                            key = Key.slice(key2, 1);
                            value = [];
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
                        trie := Trie.put(trie, key1, [1]);
                        trie := Trie.put(trie, key2, [2]);
                        trie := Trie.put(trie, key3, [3]);

                        let path = Trie.findPath(trie, key2, null);
                        let expected : Trie.Node = #leaf {
                            key = [];
                            value = [2];
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
                            ([1 : Nibble, 2, 3, 4, 5, 6], []),
                            ([1 : Nibble, 2, 3, 4, 5], []),
                            ([1 : Nibble, 2, 3], []),
                            ([1 : Nibble, 2, 3, 4], []),
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
                            ([1 : Nibble, 2, 3, 4, 5, 6], []),
                            ([1 : Nibble, 2, 3, 4, 5], []),
                            ([1 : Nibble, 2, 3], []),
                            ([1 : Nibble, 2, 3, 4], []),
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

    func section(title : Text) = Debug.print("\n#" # " " # title # "\n");

    func name(name : Text) = Debug.print("- " # name);

    public func hashTests() {
        var trie = Trie.init();
        section "Hash single elements";
        do {
            name "#nul";
            assert (Trie.hashHex(#nul)) == "56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421";
        };

        section "Hashes";
        do {
            name "New Trie";
            //Debug.print(Trie.hashHex(trie));
            assert (Trie.hashHex(trie)) == "56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421";

            name "One leaf";
            trie := Trie.init();
            trie := Trie.put(trie, Key.fromText("test"), Value.fromText("one"));
            //Debug.print(Trie.hashHex(trie));
            assert (Trie.hashHex(trie)) == "2b77e8547bc55e2a95227c939f9f9d67952de1e970a017e0910be510b090aff3";

            name "One leaf with a big value";
            trie := Trie.init();
            trie := Trie.put(trie, Key.fromText("test"), Value.fromText("abcdefghijklmnopqrstuvwxyz1234567890"));
            assert (Trie.hashHex(trie)) == "bee0f9cda4533ccb7ee8ab1a7a9c72615feb2a604d583240edf4e97eb75c2e1d";

            name "Two a big values: ext->branch(val1)->leaf(val2)";
            trie := Trie.init();
            trie := Trie.put(trie, Key.fromText("test"), Value.fromText("abcdefghijklmnopqrstuvwxyz1234567890"));
            trie := Trie.put(trie, Key.fromText("test2"), Value.fromText("abcdefghijklmnopqrstuvwxyz1234567890"));
            //Debug.print(Trie.nodeToText(trie));
            //Debug.print(Trie.hashHex(trie));
            assert (Trie.hashHex(trie)) == "7ea3b196c7c75d4267756e00db749e6b62a9ddf0162e12cfcfc6957f14ac52a2";

            name "Two a big values: ext->branch()->leaf(val1)/leaf(val2)";
            trie := Trie.init();
            trie := Trie.put(trie, Key.fromText("test1"), Value.fromText("abcdefghijklmnopqrstuvwxyz1234567890"));
            trie := Trie.put(trie, Key.fromText("test2"), Value.fromText("abcdefghijklmnopqrstuvwxyz1234567890"));
            //Debug.print(Trie.nodeToText(trie));
            //Debug.print(Trie.hashHex(trie));
            assert (Trie.hashHex(trie)) == "0666419889b0a23d855e8a677e77158da7ff183d7135915ed7a92bb1d8714f92";
        };
    };

    // Tests from the ethereumjs-monorepo
    // https://github.com/ethereumjs/ethereumjs-monorepo/blob/master/packages/trie/test/index.spec.ts
    public func ethereumJsTests() {
        var trie = Trie.init();

        section("simple save and retrieve");
        do {
            name "save a value";
            trie := Trie.put(trie, Key.fromText("test"), Value.fromText("one"));

            name "should get a value";
            assert Trie.get(trie, Key.fromText("test")) == ?Value.fromText("one");

            name "should update a value";
            trie := Trie.put(trie, Key.fromText("test"), Value.fromText("two"));
            assert Trie.get(trie, Key.fromText("test")) == ?Value.fromText("two");

            name "should delete a value";
            trie := Trie.delete(trie, Key.fromText("test"));
            assert Trie.get(trie, Key.fromText("test")) == ?[] /* TODO: replace ?[] with null */;

            name "should recreate a value";
            trie := Trie.put(trie, Key.fromText("test"), Value.fromText("one"));

            name "should get updated a value";
            assert Trie.get(trie, Key.fromText("test")) == ?Value.fromText("one");

            name "should create a branch here";
            trie := Trie.put(trie, Key.fromText("doge"), Value.fromText("coin"));
            // TODO: compare trie with at this point with eth implementation, hash doesn't match
            Debug.print(Trie.nodeToText(trie));
            Debug.print(Trie.hashHex(trie));
            assert Trie.hashHex(trie) == "de8a34a8c1d558682eae1528b47523a483dd8685d6db14b291451a66066bf0fc";

            name "should get a value that is in a branch";
            assert Trie.get(trie, Key.fromText("doge")) == ?Value.fromText("coin");

            name "should delete from a branch";
            trie := Trie.delete(trie, Key.fromText("doge"));
            assert Trie.get(trie, Key.fromText("doge")) == ?[]; // TODO: should be null

            section "storing longer values";
            do {
                trie := Trie.init();
                let longString = Value.fromText("this will be a really really really long value");
                let longStringRoot = "b173e2db29e79c78963cff5196f8a983fbe0171388972106b114ef7f5c24dfa3";

                name "should store a longer string";
                trie := Trie.put(trie, Key.fromText("done"), longString);
                trie := Trie.put(trie, Key.fromText("doge"), Value.fromText("coin"));
                //TODO: assert Trie.hashHex(trie) == longStringRoot;

                name "should retrieve a longer value";
                assert Trie.get(trie, Key.fromText("done")) == ?longString;

                name "should when being modified delete the old value";
                trie := Trie.put(trie, Key.fromText("done"), Value.fromText("test"));
            };
        };
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
