import Array "mo:base/Array";
import List "mo:base/List";
import TrieMap "mo:base/TrieMap";

import Hash "Hash";
import Hex "util/Hex";
import Key "Key";
import Trie "internal/TrieInternal";
import Value "Value";
import Result "mo:base/Result";

/// Functions to create and verify a Proof
module {
    type Hash = Hash.Hash;
    type Key = Key.Key;
    type Node = Trie.Node;
    type Path = Trie.Path;
    type Trie = Trie.Trie;
    type Value = Value.Value;
    type DB = Trie.DB;
    type Result<T, E> = Result.Result<T, E>;

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
    public func createWithoutDB(trie : Trie, key : Key) : Proof {
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

    /// Create a proof
    /// If a #hash node in the path is not found in `db`, the hash of this node is return as an error
    public func createWithDB(trie : Trie, key : Key, db : DB) : Result<Proof, Hash> {
        let path : Path = Trie.findPathWithDB(trie, key, null, db);
        switch (path.node) {
            case (#hash hash) { return #err(hash) };
            case (_) {};
        };
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

        return #ok(Array.reverse(Array.freeze(proof)));
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

        let path = Trie.findPathWithDB(#hash(root), key, null, db);

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

    /// Turn the ProofResult `val` into human readable Text
    public func proofResultToText(val : ProofResult) : Text {
        switch (val) {
            case (#included(value)) { "#included(" # Value.toHex(value) # ")" };
            case (#excluded) { "#excluded" };
            case (#invalidProof) { "#invalidProof" };
        };
    };

};
