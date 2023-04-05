import { chapter; section; test } = "../Test";

import Option "mo:base/Option";

import Trie "../../src/Trie";
import Key "../../src/Key";
import Debug "mo:base/Debug";
import Nibble "../../src/util/Nibble";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Hex "../../src/util/Hex";
import Util "../../src/util";
import Value "../../src/Value";
import Hash "../../src/Hash";

module {

    type Trie = Trie.Trie;
    type Path = Trie.Path;
    type Key = Key.Key;
    type Nibble = Nibble.Nibble;
    type Value = Value.Value;
    type Hash = Hash.Hash;

    func testKey() : Key {
        Key.fromText("key1");
    };

    public func basicTests() {
        var trie = Trie.init();
        var key = testKey();
        chapter "Basic Trie Tests";

        section "put";
        do {
            test "trie is not empty after put";
            trie := Trie.put(trie, key, Value.fromText("val"));
            assert not Trie.isEmpty(trie);

            test "get missing path";
            trie := Trie.init();
            assert Trie.pathToText(Trie.findPath(trie, key, null)) == Trie.pathToText({
                node = #nul;
                remaining = key;
                stack = null;
                mismatch = trie;
            });

            test "get existing path with branch";
            do {
                var trie = Trie.init();
                let key1 = Key.fromKeyBytes([0x12, 0x31]);
                let key2 = Key.fromKeyBytes([0x22, 0x32]);
                let key3 = Key.fromKeyBytes([0x32, 0x33]);
                trie := Trie.put(trie, key1, Value.fromText("val"));
                trie := Trie.put(trie, key2, Value.fromText("val"));
                trie := Trie.put(trie, key3, Value.fromText("val"));

                let path = Trie.findPath(trie, key2, null);
                let expected : Trie.Node = #leaf {
                    key = Key.drop(key2, 1);
                    value = Value.fromText("val");
                    var hash = null;
                };
                assert Trie.nodeEqual(path.node, expected);
            };

            test "get existing path with branch";
            do {
                var trie = Trie.init();
                let key1 = Key.fromKeyBytes([0x12, 0x31]);
                let key2 = Key.fromKeyBytes([0x22, 0x32]);
                let key3 = Key.fromKeyBytes([0x32, 0x33]);
                trie := Trie.put(trie, key1, "");
                trie := Trie.put(trie, key2, "");
                trie := Trie.put(trie, key3, "");

                let path = Trie.findPath(trie, key2, null);
                let expected : Trie.Node = #leaf {
                    key = Key.drop(key2, 1);
                    value = "";
                    var hash = null;
                };
                assert Trie.nodeEqual(path.node, expected);
            };

            test "extension -> branch -> 3 leafs";
            do {
                var trie = Trie.init();
                let key1 = Key.fromKeyBytes([0x12, 0x31]);
                let key2 = Key.fromKeyBytes([0x12, 0x32]);
                let key3 = Key.fromKeyBytes([0x12, 0x33, 0x45]);
                trie := Trie.put(trie, key1, Value.fromText("1"));
                trie := Trie.put(trie, key2, Value.fromText("2"));
                trie := Trie.put(trie, key3, Value.fromText("3"));

                let path = Trie.findPath(trie, key2, null);
                let expected : Trie.Node = #leaf {
                    key = [];
                    value = Value.fromText("2");
                    var hash = null;
                };
                //Debug.print(Trie.nodeToText(trie));
                //Debug.print(Trie.pathToText(path));
                assert Trie.nodeEqual(path.node, expected);
            };

            test "Different order should produce the same trie";
            do {
                var keyValuePairs : [(Key, Value)] = [
                    ([1 : Nibble, 2, 3, 4, 5, 6], "1"),
                    ([1 : Nibble, 2, 3, 4, 5], "2"),
                    ([1 : Nibble, 2, 3], "3"),
                    ([1 : Nibble, 2, 3, 4], "4"),
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
                        assert false;
                    };
                };

                assert Trie.equal(trie1, trie2);
            };

            test "Reinsert shouldn't change the trie";
            do {
                var keyValuePairs : [(Key, Value)] = [
                    ([1 : Nibble, 2, 3, 4, 5, 6], Value.fromText("1")),
                    ([1 : Nibble, 2, 3, 4, 5], Value.fromText("2")),
                    ([1 : Nibble, 2, 3], Value.fromText("3")),
                    ([1 : Nibble, 2, 3, 4], Value.fromText("4")),
                ];
                var trie1 = Trie.init();
                for ((key, value) in keyValuePairs.vals()) {
                    trie1 := Trie.put(trie1, key, value);
                };

                var trie2 = Trie.init();

                // check if all key are set
                for ((key, value) in keyValuePairs.vals()) {
                    trie2 := Trie.put(trie1, key, value);
                    if (not Trie.equal(trie1, trie2)) {
                        Debug.print("the trie: " # Trie.nodeToText(trie1));
                        Debug.print(" != trie: " # Trie.nodeToText(trie2));
                        assert false;
                    };
                };

                assert Trie.equal(trie1, trie2);
            };
        };

        section "iter";
        do {
            test "Get all key value pairs";
            var trie = Trie.init();
            trie := Trie.put(trie, Key.fromText("key1"), Value.fromText("value1"));
            trie := Trie.put(trie, Key.fromText("key2"), Value.fromText("value2"));
            trie := Trie.put(trie, Key.fromText("key22"), Value.fromText("value22"));
            trie := Trie.put(trie, Key.fromText("key3"), Value.fromText("value3"));
            trie := Trie.put(trie, Key.fromText("key4"), Value.fromText("value4"));

            let iter = Trie.toIter(trie);
            assert iter.next() == ?(Key.fromText("key1"), Value.fromText("value1"));
            assert iter.next() == ?(Key.fromText("key2"), Value.fromText("value2"));
            assert iter.next() == ?(Key.fromText("key22"), Value.fromText("value22"));
            assert iter.next() == ?(Key.fromText("key3"), Value.fromText("value3"));
            assert iter.next() == ?(Key.fromText("key4"), Value.fromText("value4"));
            assert iter.next() == null;

        };
    };

    public func hashTests() {
        var trie = Trie.init();
        section "Hash single elements";
        do {
            test "#nul";
            assert (Trie.hashHex(#nul)) == "56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421";

            test "#leaf";
            let leaf : Trie.Leaf = {
                key = [7, 4, 6, 5, 7, 3, 7, 4];
                value = Value.fromText("one");
                var hash = null;
            };
            //Debug.print(Trie.hashHex(#leaf leaf));
            assert (Trie.hashHex(#leaf leaf)) == "2b77e8547bc55e2a95227c939f9f9d67952de1e970a017e0910be510b090aff3";

            test "#branch";
            let branch : Trie.Branch = {
                nodes = [#nul, #nul, #nul, #nul, #nul, #nul, #nul, #nul, #nul, #nul, #nul, #nul, #nul, #nul, #nul, #nul];
                value = ?Value.fromText("one");
                var hash = null;
            };
            //Debug.print(Trie.hashHex(#branch branch));
            assert (Trie.hashHex(#branch branch)) == "5798fa3858f12926c10e79dfae7fc774672634926d378c404d3ded09465f6866";

            test "#hash";
            let bytes = Option.get<Hash>(Hash.fromHex("5798fa3858f12926c10e79dfae7fc774672634926d378c404d3ded09465f6866"), "");
            let hash : Trie.Node = #hash(bytes);
            assert (Trie.hashHex(hash)) == "5798fa3858f12926c10e79dfae7fc774672634926d378c404d3ded09465f6866";

        };

        section "Hashes";
        do {
            test "New Trie";
            //Debug.print(Trie.hashHex(trie));
            assert (Trie.hashHex(trie)) == "56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421";

            test "One leaf";
            trie := Trie.init();
            trie := Trie.put(trie, Key.fromText("test"), Value.fromText("one"));
            //Debug.print(Trie.hashHex(trie));
            assert (Trie.hashHex(trie)) == "2b77e8547bc55e2a95227c939f9f9d67952de1e970a017e0910be510b090aff3";

            test "One leaf with a big value";
            trie := Trie.init();
            trie := Trie.put(trie, Key.fromText("test"), Value.fromText("abcdefghijklmnopqrstuvwxyz1234567890"));
            assert (Trie.hashHex(trie)) == "bee0f9cda4533ccb7ee8ab1a7a9c72615feb2a604d583240edf4e97eb75c2e1d";

            test "Two big values: ext->branch(val1)->leaf(val2)";
            trie := Trie.init();
            trie := Trie.put(trie, Key.fromText("test"), Value.fromText("abcdefghijklmnopqrstuvwxyz1234567890"));
            trie := Trie.put(trie, Key.fromText("test2"), Value.fromText("abcdefghijklmnopqrstuvwxyz1234567890"));
            //Debug.print(Trie.nodeToText(trie));
            //Debug.print(Trie.hashHex(trie));
            assert (Trie.hashHex(trie)) == "7ea3b196c7c75d4267756e00db749e6b62a9ddf0162e12cfcfc6957f14ac52a2";

            test "Two small values: ext->branch()->leaf(val1)/leaf(val2)";
            trie := Trie.init();
            trie := Trie.put(trie, Key.fromText("test1"), Value.fromText("abcdefghijklmnopqrstuvwxyz1234567890"));
            trie := Trie.put(trie, Key.fromText("test2"), Value.fromText("abcdefghijklmnopqrstuvwxyz1234567890"));
            //Debug.print(Trie.nodeToText(trie));
            //Debug.print(Trie.hashHex(trie));
            //Debug.print("expected: 0666419889b0a23d855e8a677e77158da7ff183d7135915ed7a92bb1d8714f92");
            assert (Trie.hashHex(trie)) == "0666419889b0a23d855e8a677e77158da7ff183d7135915ed7a92bb1d8714f92";

            test "Two small values: branch()->leaf(val1)/leaf(val2)";
            trie := Trie.init();
            trie := Trie.put(trie, Key.fromText("1"), Value.fromText("one"));
            trie := Trie.put(trie, Key.fromText("x"), Value.fromText("two"));
            //Debug.print(Trie.nodeToText(trie));
            //Debug.print(Trie.hashHex(trie));
            assert (Trie.hashHex(trie)) == "dd833fd93e1a5e2e221d74e8a3fc594f3bb43b5d0edbf24c6c3c95ab2f0615fe";

            test "keep short rlp encoded values, hash long values";
            let hashes = [
                // reference hashes were generated using the ethereumjs trie library
                "e8e4a30ec58b7b915b4c7f7276663b95a1bd725ea0ea378d8da55956ebb6692d",
                "1b5614127f3503831daadeefc30499f27edd18b7376df2b027dd40c81f7d7e66",
                "fa1f0b535e834b2f869728ce13396be068205e4eb7e100933b804479b2465870",
                "5706358e564677a3233713d614429e8422be3dd6011e831d8454ae7eb1244c09",
                "3d02333a7af77c5968b861755eeb5747c75f458b3234a421974d8a033c79d173",
                "730b9deea969f5b9d24d664f289fdf6c91621f27d92c0843e594fa6a1bf653af",
                "fd02a38b9af40f22e1586e5719f425a5aea29751d8a818e137e2cb23b811052e",
                "f9d4d7e90e3ab9402ddee163d97dd5524f333fbf07221950f0284027e525aaa6",
                "aaa63abdd9c2c42de165ae665f59deeb528827f3c6b60cfe4635612fbaba60cd",
                "71abdbc8be465ea4e312ccdac425e09c443bde11a94b53a6c9c4ab71db2551c2",
                "9351fb065da980a1583cb3775dc872b63a54339ba6feed66cf1108d0f22d7dda",
                "a89a9063f5134f98eaa5f11f5d264eb08e9bedfdba4d697d27977b9fc107c025",
                "4114fda6fb0313bae74590bbc5a6ea07250dbab977a0663aebddd3c24a2a5e30",
                "5569f95067b99b54ae88da127b7d81aded69600e068be7f24be273f92ff31a64",
                "34f98e2bfea42eb1b3ad14dc77894e6b6322a0fa33d17049440af99d6b35df29",
                "25d433e1fabb2abc4429aa3cbbce16ffe91f494f1bc6490f10e1710c087c315d",
                "460ee005d7b69878641bd6e8c3e4f7755d9133e7ddd509cb431a378a2bb749c2",
                "6b91b6cd61b8a1aaa804a5983905d7497e3c30e24eaecf5e1caa0c06edf444b3",
                "b7007a98beda1298e03c0d1e7d4f60ec99a2208b592996bbd8dc4216fd1403af",
                "9c1f212d7622634a9edc34d0eab415d98797892ec8e91a7d9c92a01e87e0a2e9",
                "3876ce4d3e14d9582bb266af0d82e5901ce6e2cb25510110350ed353403cd395",
                "bb439320a37815374a2c3845881262eda66998548db40aa73053beccdfc7e951",
                "82e0904e8ff636d70a938163d93c01003a6c457d3768601c0d3e7c0f1948a4cf",
                "287744c590b6943409005ef98f9f66d3686d199f29f40282eb938016f3f761a3",
                "a83032157cc2852d849aea4aa87bdc1ef7668e5bb706dbb8ef45dbed5bcb45b7",
                "dfee2e5018658207b620f76c1f44f5d2717a71bf58cbef539382999fc55c4bb9",
                "b1fbf92003b61d665ac43011beac8a00d9a897359467c13771bc26d728a06a0c",
                "87c7ab582e35ebcd8a4afa173b1492d6036c11b47cfc3d5098b52ec6c94cb3ca",
                "01b3e2b60687f3ec4b0e7435d467f04e609739bd4679a6b47429752381530478",
                "098c0f85e303a5462d661e5327a76e39bc0366140277b2cad7922f46a2278079",
            ];

            var value = "";
            for (i in Iter.range(0, hashes.size() - 1)) {
                value #= "x"; // add on x to the value -> "x", "xx", "xxx", ...
                trie := Trie.init();
                trie := Trie.put(trie, Key.fromText("te"), Value.fromText("branch"));
                trie := Trie.put(trie, Key.fromText("test"), Value.fromText(value));
                assert Trie.hashHex(trie) == hashes[i];
            };
        };
    };

    // Tests from the ethereumjs-monorepo
    // https://github.com/ethereumjs/ethereumjs-monorepo/blob/master/packages/trie/test/index.spec.ts
    public func ethereumJsTests() {
        var trie = Trie.init();

        section("simple save and retrieve");
        do {
            test "save a value";
            trie := Trie.put(trie, Key.fromText("test"), Value.fromText("one"));

            test "should get a value";
            assert Trie.get(trie, Key.fromText("test")) == ?Value.fromText("one");

            test "should update a value";
            trie := Trie.put(trie, Key.fromText("test"), Value.fromText("two"));
            assert Trie.get(trie, Key.fromText("test")) == ?Value.fromText("two");

            test "should delete a value";
            trie := Trie.delete(trie, Key.fromText("test"));
            assert Trie.get(trie, Key.fromText("test")) == ?"" /* TODO: replace ?[] with null */;

            test "should recreate a value";
            trie := Trie.put(trie, Key.fromText("test"), Value.fromText("one"));

            test "should get updated a value";
            assert Trie.get(trie, Key.fromText("test")) == ?Value.fromText("one");

            test "should create a branch here";
            trie := Trie.put(trie, Key.fromText("doge"), Value.fromText("coin"));
            //Debug.print(Trie.nodeToText(trie));
            //Debug.print(Trie.hashHex(trie));
            assert Trie.hashHex(trie) == "de8a34a8c1d558682eae1528b47523a483dd8685d6db14b291451a66066bf0fc";

            test "should get a value that is in a branch";
            assert Trie.get(trie, Key.fromText("doge")) == ?Value.fromText("coin");

            test "should delete from a branch";
            trie := Trie.delete(trie, Key.fromText("doge"));
            assert Trie.get(trie, Key.fromText("doge")) == ?""; // TODO: should be null

            section "storing longer values";
            do {
                trie := Trie.init();
                let longString = Value.fromText("this will be a really really really long value");
                let longStringRoot = "b173e2db29e79c78963cff5196f8a983fbe0171388972106b114ef7f5c24dfa3";

                test "should store a longer string";
                trie := Trie.put(trie, Key.fromText("done"), longString);
                trie := Trie.put(trie, Key.fromText("doge"), Value.fromText("coin"));
                assert Trie.hashHex(trie) == longStringRoot;

                test "should retrieve a longer value";
                assert Trie.get(trie, Key.fromText("done")) == ?longString;

                test "should when being modified delete the old value";
                trie := Trie.put(trie, Key.fromText("done"), Value.fromText("test"));
            };

            section "testing extensions and branches";
            do {
                trie := Trie.init();

                test "should store a value";
                trie := Trie.put(trie, Key.fromText("doge"), Value.fromText("coin"));

                test "should create extension to store this value";
                trie := Trie.put(trie, Key.fromText("do"), Value.fromText("verb"));
                assert Trie.hashHex(trie) == "f803dfcb7e8f1afd45e88eedb4699a7138d6c07b71243d9ae9bff720c99925f9";

                test "should store this value under the extension";
                trie := Trie.put(trie, Key.fromText("done"), Value.fromText("finished"));
                assert Trie.hashHex(trie) == "409cff4d820b394ed3fb1cd4497bdd19ffa68d30ae34157337a7043c94a3e8cb";
            };

            section "testing extensions and branches - reverse";
            do {
                trie := Trie.init();

                test "should create extension to store this value";
                trie := Trie.put(trie, Key.fromText("do"), Value.fromText("verb"));

                test "should store a value";
                trie := Trie.put(trie, Key.fromText("doge"), Value.fromText("coin"));

                test "should store this value under the extension";
                trie := Trie.put(trie, Key.fromText("done"), Value.fromText("finished"));
                assert Trie.hashHex(trie) == "409cff4d820b394ed3fb1cd4497bdd19ffa68d30ae34157337a7043c94a3e8cb";
            };
        };
    };

};
