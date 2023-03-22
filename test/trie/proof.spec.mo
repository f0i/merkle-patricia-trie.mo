import { chapter; section; test } = "../Test";

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

    public func ethereumjsTests() {
        chapter "simple merkle proofs generation and verification";
        var trie = Trie.init();

        section "create a merkle proof and verify it";
        do {
            trie := Trie.put(trie, Key.fromText("key1aa"), Buffer.fromText("0123456789012345678901234567890123456789xx"));
            trie := Trie.put(trie, Key.fromText("key2bb"), Buffer.fromText("aval2"));
            trie := Trie.put(trie, Key.fromText("key3cc"), Buffer.fromText("aval3"));

            let root = Trie.hash(trie);
            var proof = Trie.createProof(trie, Key.fromText("key2bb"));
            var val = Trie.verifyProof(root, Key.fromText("key2bb"), proof);
            switch (val) {
                case (?value) { Debug.print("value found") };
                case (null) { Debug.print("No value found") };
            };
            //TODO: assert val == ?(Buffer.fromText("aval2"));

            proof := Trie.createProof(trie, Key.fromText("key1aa"));
            val := Trie.verifyProof(root, Key.fromText("key1aa"), proof);
            //TODO: assert val == ?(Buffer.fromText("0123456789012345678901234567890123456789xx"));
        };

    };
};
