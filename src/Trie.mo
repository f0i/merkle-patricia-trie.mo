import Trie "internal/Trie";
import Value "Value";
import Key "Key";
import Iter "mo:base/Iter";
import Hash "Hash";
/// Proxy module exposing some function of internal/Trie.mo

module {
    type Iter<T> = Iter.Iter<T>;
    type Key = Key.Key;
    type Value = Value.Value;
    type Hash = Hash.Hash;

    /// Data structure and functions to manipulate and query a Merkle Patricia Trie.
    public type Trie = Trie.Trie;

    /// Create an empty trie
    public func init() : Trie = Trie.init();

    /// Add a value into a trie
    /// If value is empty, the key will be deleted
    public func put(trie : Trie, key : Key, value : Value) : Trie {
        Trie.put(trie, key, value);
    };

    /// Get the value for a specific key
    public func get(trie : Trie, key : Key) : ?Value {
        Trie.get(trie, key);
    };

    /// Delete a key from a trie
    public func delete(trie : Trie, key : Key) : Trie = Trie.delete(trie, key);

    /// Get a root hash of a Trie
    public func hash(trie : Trie) : Hash = Trie.rootHash(trie);

    /// Get root hash as a hex Text
    public func hashHex(trie : Trie) : Text = Trie.hashHex(trie);

    /// Get an Iter to get all Key/Value pairs
    public func entries(trie : Trie) : Iter<(Key, Value)> = Trie.toIter(trie);

    /// Check if Trie `a` is equal to Trie `b`
    public func equal(a : Trie, b : Trie) : Bool = Trie.equal(a, b);

    /// Get the whole trie as a human readable Text
    public func toText(trie : Trie) : Text = Trie.nodeToText(trie);
};
