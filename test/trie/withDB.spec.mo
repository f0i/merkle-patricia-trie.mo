import { chapter; section; test } = "../Test";

import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import TrieMap "mo:base/TrieMap";

import Hash "../../src/Hash";
import Hex "../../src/util/Hex";
import Key "../../src/Key";
import Nibble "../../src/util/Nibble";
import Trie "../../src/TrieWithDB";
import Util "../../src/util";
import { unwrap } "../../src/util";
import Value "../../src/Value";

module {

    type Hash = Hash.Hash;
    type Node = Trie.Node;

    public func tests() {
        chapter "TrieWithDB";
        var trie = Trie.init();

        let map = TrieMap.TrieMap<Hash, Node>(Hash.equal, Hash.hash);

        // create a db wrapper (Just to show how it could be done)
        var db = {
            put = func(hash : Hash, node : Node) {
                map.put(hash, node);
            };
            get = func(hash : Hash) : ?Node {
                map.get(hash);
            };
        };

        test "put";
        switch (Trie.put(trie, Key.fromText("key1"), Value.fromText("val1"), db)) {
            case (#ok(newTrie)) { trie := newTrie };
            case (#err(msg)) { assert false };
        };

        switch (Trie.get(trie, Key.fromText("key1"), db)) {
            case (#ok(value)) {
                assert value == ?Value.fromText("val1");
            };
            case (#err(error)) { assert false };
        };
    };

    public func ethereumJsTests() {
        chapter "EthereumJS tests withDB";
        var trie = Trie.init();
        let db = TrieMap.TrieMap<Hash, Node>(Hash.equal, Hash.hash);

        section("simple save and retrieve");
        do {
            test "save a value";
            trie := unwrap(Trie.put(trie, Key.fromText("test"), Value.fromText("one"), db));

            test "should get a value";
            assert unwrap(Trie.get(trie, Key.fromText("test"), db)) == ?Value.fromText("one");

            test "should update a value";
            trie := unwrap(Trie.put(trie, Key.fromText("test"), Value.fromText("two"), db));
            assert unwrap(Trie.get(trie, Key.fromText("test"), db)) == ?Value.fromText("two");

            test "should delete a value";
            trie := unwrap(Trie.delete(trie, Key.fromText("test"), db));
            assert unwrap(Trie.get(trie, Key.fromText("test"), db)) == null;

            test "should recreate a value";
            trie := unwrap(Trie.put(trie, Key.fromText("test"), Value.fromText("one"), db));

            test "should get updated a value";
            assert unwrap(Trie.get(trie, Key.fromText("test"), db)) == ?Value.fromText("one");

            test "should create a branch here";
            trie := unwrap(Trie.put(trie, Key.fromText("doge"), Value.fromText("coin"), db));
            //Debug.print(Trie.nodeToText(trie));
            //Debug.print(Trie.hashHex(trie));
            assert Trie.hashHex(trie) == "de8a34a8c1d558682eae1528b47523a483dd8685d6db14b291451a66066bf0fc";

            test "should get a value that is in a branch";
            assert unwrap(Trie.get(trie, Key.fromText("doge"), db)) == ?Value.fromText("coin");

            test "should delete from a branch";
            trie := unwrap(Trie.delete(trie, Key.fromText("doge"), db));
            assert unwrap(Trie.get(trie, Key.fromText("doge"), db)) == null;

            section "storing longer values";
            do {
                trie := Trie.init();
                let longString = Value.fromText("this will be a really really really long value");
                let longStringRoot = "b173e2db29e79c78963cff5196f8a983fbe0171388972106b114ef7f5c24dfa3";

                test "should store a longer string";
                trie := unwrap(Trie.put(trie, Key.fromText("done"), longString, db));
                trie := unwrap(Trie.put(trie, Key.fromText("doge"), Value.fromText("coin"), db));
                assert Trie.hashHex(trie) == longStringRoot;

                test "should retrieve a longer value";
                assert unwrap(Trie.get(trie, Key.fromText("done"), db)) == ?longString;

                test "should when being modified delete the old value";
                trie := unwrap(Trie.put(trie, Key.fromText("done"), Value.fromText("test"), db));
            };

            section "testing extensions and branches";
            do {
                trie := Trie.init();

                test "should store a value";
                trie := unwrap(Trie.put(trie, Key.fromText("doge"), Value.fromText("coin"), db));

                test "should create extension to store this value";
                trie := unwrap(Trie.put(trie, Key.fromText("do"), Value.fromText("verb"), db));
                assert Trie.hashHex(trie) == "f803dfcb7e8f1afd45e88eedb4699a7138d6c07b71243d9ae9bff720c99925f9";

                test "should store this value under the extension";
                trie := unwrap(Trie.put(trie, Key.fromText("done"), Value.fromText("finished"), db));
                assert Trie.hashHex(trie) == "409cff4d820b394ed3fb1cd4497bdd19ffa68d30ae34157337a7043c94a3e8cb";
            };

            section "testing extensions and branches - reverse";
            do {
                trie := Trie.init();

                test "should create extension to store this value";
                trie := unwrap(Trie.put(trie, Key.fromText("do"), Value.fromText("verb"), db));

                test "should store a value";
                trie := unwrap(Trie.put(trie, Key.fromText("doge"), Value.fromText("coin"), db));

                test "should store this value under the extension";
                trie := unwrap(Trie.put(trie, Key.fromText("done"), Value.fromText("finished"), db));
                assert Trie.hashHex(trie) == "409cff4d820b394ed3fb1cd4497bdd19ffa68d30ae34157337a7043c94a3e8cb";
            };
        };
    };
};
