import Trie "internal/Trie";
import Value "Value";
import Key "Key";
import Iter "mo:base/Iter";
import Hash "Hash";
import Result "mo:base/Result";
/// Proxy module exposing some function of internal/Trie.mo

module {
    type Iter<T> = Iter.Iter<T>;
    type Result<T, E> = Result.Result<T, E>;
    type Key = Key.Key;
    type Value = Value.Value;
    type Hash = Hash.Hash;

    /// Data structure and functions to manipulate and query a Merkle Patricia Trie.
    public type Trie = Trie.Trie;

    /// A Node object
    public type Node = Trie.Node;

    /// Interface for a database
    public type DB = Trie.DB;

    /// Create an empty trie
    public func init() : Trie = Trie.init();

    /// Add a value into a trie
    /// If value is empty, the key will be deleted
    public func put(trie : Trie, key : Key, value : Value, db : DB) : Result<Trie, Hash> {
        Trie.putWithDB(trie, key, value, db);
    };

    /// Get the value for a specific key
    public func get(trie : Trie, key : Key, db : DB) : Result<?Value, Text> {
        Trie.getWithDB(trie, key, db);
    };

    /// Delete a key from a trie
    public func delete(trie : Trie, key : Key, db : DB) : Result<Trie, Hash> {
        Trie.deleteWithDB(trie, key, db);
    };

    /// Get a root hash of a Trie
    public func hash(trie : Trie) : Hash = Trie.rootHash(trie);

    /// Get root hash as a hex Text
    public func hashHex(trie : Trie) : Text = Trie.hashHex(trie);

    /// Get an Iter to get all Key/Value pairs
    public func entries(trie : Trie, db : DB) : Iter<(Key, Value)> = Trie.toIterWithDB(trie, db);

    /// Check if Trie `a` is equal to Trie `b`
    public func equal(a : Trie, b : Trie) : Bool = Trie.equal(a, b);

    /// Get the whole trie as a human readable Text
    public func toText(trie : Trie, db : DB) : Text = Trie.nodeToTextWithDB(trie, db);
};
