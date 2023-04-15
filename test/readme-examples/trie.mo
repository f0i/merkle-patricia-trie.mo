import Trie "mo:merkle-patricia-trie/Trie";
import Key "mo:merkle-patricia-trie/Key";
import Value "mo:merkle-patricia-trie/Value";
import Hash "mo:merkle-patricia-trie/Hash";
import Proof "mo:merkle-patricia-trie/Proof";
import Debug "mo:base/Debug";

// Create an empty trie and add a key/value pair
var trie = Trie.init();
trie := Trie.put(trie, Key.fromText("one"), Value.fromText("value1"));

// Get value
let value = Trie.get(trie, Key.fromText("one"));
assert value == ?Value.fromText("value1");

// Get the root hash of the trie
let hash = Trie.hash(trie);

// Create a proof
let proof = Proof.create(trie, Key.fromText("one"));

// Verify the proof against the root hash
let proofResult = Proof.verify(hash, Key.fromText("one"), proof);

// Print proof result
switch (proofResult) {
    case (#included value) {
        Debug.print("Proof was valid and returned value " # Value.toHex(value));
    };
    case (#excluded) {
        Debug.print("Proof was valid and key is not included in trie");
    };
    case (#invalidProof) {
        Debug.print("Proof was invalid. Can not make statement about the key");
    };
};
