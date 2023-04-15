import { chapter; section; test } = "../Test";

import Trie "../../src/internal/Trie";
import Key "../../src/Key";
import Debug "mo:base/Debug";
import Nibble "../../src/util/Nibble";
import Array "mo:base/Array";
import Hex "../../src/util/Hex";
import Util "../../src/util";
import Value "../../src/Value";
import Text "mo:base/Text";
import Blob "mo:base/Blob";
import Proof "../../src/Proof";

module {
    type Trie = Trie.Trie;
    type Value = Value.Value;
    type Key = Key.Key;
    type Nibble = Nibble.Nibble;

    public func tests() {
        chapter "proof helper functions";

        section "serialize";
        do {
            test "serialize leaf";
            let leaf : Trie.Node = Trie.createLeaf(Key.fromText("test"), Value.fromText("value"));
            let bytes = Trie.nodeSerialize(leaf);
            //Debug.print("bytes " # Hex.toText(bytes));
            assert bytes == Util.unwrap(Hex.toArray("cc8520746573748576616c7565"));

            test "deserialize leaf";
            let node : Trie.Node = Trie.nodeDecode(bytes);
            assert Trie.nodeEqual(node, leaf);
        };
    };

    public func ethereumjsTests() {
        chapter "Simple merkle proofs generation and verification";
        var trie = Trie.init();

        section "create a merkle proof and verify it";
        do {
            trie := Trie.put(trie, Key.fromText("key1aa"), Value.fromText("0123456789012345678901234567890123456789xx"));
            trie := Trie.put(trie, Key.fromText("key2bb"), Value.fromText("aval2"));
            trie := Trie.put(trie, Key.fromText("key3cc"), Value.fromText("aval3"));

            var root = Trie.rootHash(trie);

            test "create a proof";
            var proof = Proof.create(trie, Key.fromText("key2bb"));
            assert proof == [
                Util.unwrap(Hex.toArray("e68416b65793a03101b4447781f1e6c51ce76c709274fc80bd064f3a58ff981b6015348a826386")),
                Util.unwrap(Hex.toArray("f84580a0582eed8dd051b823d13f8648cdcd08aa2d8dac239f458863c4620e8c4d605debca83206262856176616c32ca83206363856176616c3380808080808080808080808080")),
                Util.unwrap(Hex.toArray("ca83206262856176616c32")),
            ];

            test "verify proofs";
            var val = Proof.verify(root, Key.fromText("key2bb"), proof);
            assert val == #included(Value.fromText("aval2"));

            proof := Proof.create(trie, Key.fromText("key1aa"));
            val := Proof.verify(root, Key.fromText("key1aa"), proof);
            assert val == #included(Value.fromText("0123456789012345678901234567890123456789xx"));

            test "Expected value at 'key2' to be null";
            proof := Proof.create(trie, Key.fromText("key2bb"));
            val := Proof.verify(root, Key.fromText("key2"), proof);
            // In this case, the proof _happens_ to contain enough nodes to prove `key2` because
            // traversing into `key2bb` would touch all the same nodes as traversing into `key2`
            assert val == #excluded;

            test "Expected value for a random key to be null";
            var myKey = Key.fromText("anyrandomkey");
            proof := Proof.create(trie, myKey);
            //Debug.print("proof: " # Hex.toText2D(proof));
            val := Proof.verify(root, myKey, proof);
            assert val == #excluded;

            test "extra nodes are just ignored";
            myKey := Key.fromText("anothergarbagekey"); // should generate a valid proof of null
            proof := Proof.create(trie, myKey);
            proof := Array.append(proof, [Blob.toArray(Text.encodeUtf8("123456"))]); // extra nodes are just ignored
            val := Proof.verify(root, myKey, proof);
            assert val == #excluded;

            trie := Trie.put(trie, Key.fromText("another"), Value.fromText("3498h4riuhgwe"));
            root := Trie.rootHash(trie);

            test "to fail our proof we can request a proof for one key, and try to use that proof on another key";
            proof := Proof.create(trie, Key.fromText("another"));
            val := Proof.verify(root, Key.fromText("key1aa"), proof);
            assert val == #invalidProof;

            test "we can also corrupt a valid proof";
            proof := Proof.create(trie, Key.fromText("key2bb"));
            let p = Array.thaw<[Nat8]>(proof);
            p[0] := Array.reverse(p[0]);
            proof := Array.freeze(p);
            val := Proof.verify(root, Key.fromText("key2bb"), proof);
            assert val == #invalidProof;

            test "test an invalid exclusion proof by creating a valid exclusion proof (and later making it non-null)";
            myKey := Key.fromText("anyrandomkey");
            proof := Proof.create(trie, myKey);
            val := Proof.verify(root, myKey, proof);
            assert val == #excluded;

            test "now make the key non-null so the exclusion proof becomes invalid";
            trie := Trie.put(trie, myKey, Value.fromText("thisisavalue"));
            root := Trie.rootHash(trie);

            val := Proof.verify(root, myKey, proof);
            assert val == #invalidProof;
        };

        test "create a merkle proof and verify it with a single long key";
        trie := Trie.init();
        trie := Trie.put(trie, Key.fromText("key1aa"), Value.fromText("0123456789012345678901234567890123456789xx"));
        var root = Trie.rootHash(trie);
        var proof = Proof.create(trie, Key.fromText("key1aa"));
        var val = Proof.verify(root, Key.fromText("key1aa"), proof);
        assert val == #included(Value.fromText("0123456789012345678901234567890123456789xx"));

        test "create a merkle proof and verify it with a single short key";
        trie := Trie.init();
        trie := Trie.put(trie, Key.fromText("key1aa"), Value.fromText("01234"));
        root := Trie.rootHash(trie);
        proof := Proof.create(trie, Key.fromText("key1aa"));
        val := Proof.verify(root, Key.fromText("key1aa"), proof);
        assert val == #included(Value.fromText("01234"));

        test "create a merkle proof and verify it whit keys in the middle ";
        trie := Trie.init();

        trie := Trie.put(
            trie,
            Key.fromText("key1aa"),
            Value.fromText("0123456789012345678901234567890123456789xxx"),
        );
        trie := Trie.put(
            trie,
            Key.fromText("key1"),
            Value.fromText("0123456789012345678901234567890123456789Very_Long"),
        );
        trie := Trie.put(trie, Key.fromText("key2bb"), Value.fromText("aval3"));
        trie := Trie.put(trie, Key.fromText("key2"), Value.fromText("short"));
        trie := Trie.put(trie, Key.fromText("key3cc"), Value.fromText("aval3"));
        trie := Trie.put(trie, Key.fromText("key3"), Value.fromText("1234567890123456789012345678901"));
        root := Trie.rootHash(trie);

        proof := Proof.create(trie, Key.fromText("key1"));
        val := Proof.verify(root, Key.fromText("key1"), proof);
        assert val == #included(Value.fromText("0123456789012345678901234567890123456789Very_Long"));

        proof := Proof.create(trie, Key.fromText("key2"));
        val := Proof.verify(root, Key.fromText("key2"), proof);
        assert val == #included(Value.fromText("short"));

        proof := Proof.create(trie, Key.fromText("key3"));
        val := Proof.verify(root, Key.fromText("key3"), proof);
        assert val == #included(Value.fromText("1234567890123456789012345678901"));

        test "should succeed with a simple embedded extension-branch";
        trie := Trie.init();

        trie := Trie.put(trie, Key.fromText("a"), Value.fromText("a"));
        trie := Trie.put(trie, Key.fromText("b"), Value.fromText("b"));
        trie := Trie.put(trie, Key.fromText("c"), Value.fromText("c"));
        root := Trie.rootHash(trie);

        proof := Proof.create(trie, Key.fromText("a"));
        val := Proof.verify(root, Key.fromText("a"), proof);
        assert val == #included(Value.fromText("a"));

        proof := Proof.create(trie, Key.fromText("b"));
        val := Proof.verify(root, Key.fromText("b"), proof);
        assert val == #included(Value.fromText("b"));

        proof := Proof.create(trie, Key.fromText("c"));
        val := Proof.verify(root, Key.fromText("c"), proof);
        assert val == #included(Value.fromText("c"));

    };

};
