import { chapter; section; test } = "../Test";

import Buffer "../../src/util/Buffer";
import Trie "../../src/MerklePatriciaTrie";
import Key "../../src/trie/Key";
import Debug "mo:base/Debug";
import Nibble "../../src/util/Nibble";
import Array "mo:base/Array";
import Value "../../src/util/Value";
import Hex "../../src/util/Hex";
import Util "../../src/util";

module {
    type Trie = Trie.Trie;
    type Path = Trie.Path;
    type Buffer = Buffer.Buffer;
    type Key = Key.Key;
    type Nibble = Nibble.Nibble;

    public func tests() {
        chapter "proof helper functions";

        section "serialize";
        do {
            test "serialize leaf";
            let leaf = Trie.createLeaf(Key.fromText("test"), Buffer.fromText("value"));
            let bytes = Trie.nodeSerialize(leaf);
            //Debug.print("bytes " # Hex.toText(bytes));
            assert bytes == Util.unwrap(Hex.toArray("cc8520746573748576616c7565"));

            test "deserialize leaf";
            let node = Trie.nodeDecode(bytes);
            assert node == leaf;
        };
    };

    public func ethereumjsTests() {
        chapter "Proofs";

        section "simple merkle proofs generation and verification";
        var trie = Trie.init();

        section "create a merkle proof and verify it";
        do {
            trie := Trie.put(trie, Key.fromText("key1aa"), Buffer.fromText("0123456789012345678901234567890123456789xx"));
            trie := Trie.put(trie, Key.fromText("key2bb"), Buffer.fromText("aval2"));
            trie := Trie.put(trie, Key.fromText("key3cc"), Buffer.fromText("aval3"));

            let root = Trie.hash(trie);

            test "create a proof";
            var proof = Trie.createProof(trie, Key.fromText("key2bb"));
            assert proof == [
                Util.unwrap(Hex.toArray("e68416b65793a03101b4447781f1e6c51ce76c709274fc80bd064f3a58ff981b6015348a826386")),
                Util.unwrap(Hex.toArray("f84580a0582eed8dd051b823d13f8648cdcd08aa2d8dac239f458863c4620e8c4d605debca83206262856176616c32ca83206363856176616c3380808080808080808080808080")),
                Util.unwrap(Hex.toArray("ca83206262856176616c32")),
            ];

            test "verify proofs";
            var val = Trie.verifyProof(root, Key.fromText("key2bb"), proof);
            assert val == ?(Buffer.fromText("aval2"));

            proof := Trie.createProof(trie, Key.fromText("key1aa"));
            val := Trie.verifyProof(root, Key.fromText("key1aa"), proof);
            assert val == ?(Buffer.fromText("0123456789012345678901234567890123456789xx"));
        };

    };
};
