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
import Trie "../../src/Trie";
import Util "../../src/util";
import Value "../../src/Value";

module {

    type Hash = Hash.Hash;
    type Node = Trie.Node;

    public func testWithDB() {
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
        switch (Trie.putWithDB(trie, Key.fromText("key1"), Value.fromText("val1"), db)) {
            case (#ok(newTrie)) { trie := newTrie };
            case (#err(msg)) { assert false };
        };

        switch (Trie.getWithDb(trie, Key.fromText("key1"), db)) {
            case (#ok(value)) {
                assert value == ?Value.fromText("val1");
            };
            case (#err(error)) { assert false };
        };
    };

};
