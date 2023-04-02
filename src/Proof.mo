import Trie "Trie";
import Key "Key";
import Value "Value";
import List "mo:base/List";
import Array "mo:base/Array";
import Hex "util/Hex";
import TrieMap "mo:base/TrieMap";
import Hash "Hash";

module {
    type Trie = Trie.Trie;
    type Path = Trie.Path;
    type Node = Trie.Node;
    type Value = Value.Value;
    type Hash = Trie.Hash;
    type Key = Key.Key;

    /// Proof data
    public type Proof = [[Nat8]];

    /// Result of a proof verification
    public type ProofResult = {
        #included : Value;
        #excluded;
        #invalidProof;
    };

    /// Create a proof
    /// `trie` must be a full trie (no #hash node in the path of `key`)
    public func create(trie : Trie, key : Key) : Proof {
        let path : Path = Trie.findPath(trie, key, null);
        let stackSize = List.size(path.stack);
        var size = stackSize + 1;
        switch (path.mismatch) {
            case (#nul) {};
            case (_) { size += 1 };
        };
        var proof = Array.init<[Nat8]>(size, []);

        if (path.remaining == []) {
            proof[0] := Trie.nodeSerialize(path.node);
        } else {
            proof[0] := Trie.nodeSerialize(path.mismatch);
        };

        var i = 1;
        for ((k, node) in List.toIter(path.stack)) {
            proof[i] := Trie.nodeSerialize(node);
            i += 1;
        };

        return Array.reverse(Array.freeze(proof));
    };

    /// Convert a proof to a human readable Text
    func toText(proof : Proof) : Text {
        Hex.toText2D(proof);
    };

    /// Verify a proof
    public func verify(root : Hash, key : Key, proof : Proof) : ProofResult {
        let db = TrieMap.TrieMap<Hash, Node>(Hash.equal, Hash.hash);
        var first = true;
        for (item in proof.vals()) {
            let node = Trie.nodeDecode(item);
            let hash1 = Trie.nodeHash(node);
            db.put(hash1, node);
            if (first and hash1.size() < 32) {
                let hash2 = Trie.rootHash(node);
                db.put(hash2, node);
            };
            first := false;
        };

        let path = Trie.findPathWithDb(#hash(root), key, null, db);

        if (path.remaining.size() > 0) {
            switch (path.node) {
                case (#hash(hash)) {
                    return #invalidProof

                };
                case (_) { return #excluded };
            };
        };

        switch (Trie.nodeValue(path.node)) {
            case (null) { return #excluded };
            case (?value) { return #included(value) };
        };
    };

    public func proofResultToText(val : ProofResult) : Text {
        switch (val) {
            case (#included(value)) { "#included(" # Value.toHex(value) # ")" };
            case (#excluded) { "#excluded" };
            case (#invalidProof) { "#invalidProof" };
        };
    };

};
