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

    public type Trie = Trie.Trie;

    public type Node = Trie.Node;

    public type DB = Trie.DB;

    public func init() : Trie = Trie.init();

    public func put(trie : Trie, key : Key, value : Value, db : DB) : Result<Trie, Hash> {
        Trie.putWithDB(trie, key, value, db);
    };

    public func get(trie : Trie, key : Key, db : DB) : Result<?Value, Text> {
        Trie.getWithDB(trie, key, db);
    };

    public func delete(trie : Trie, key : Key, db : DB) : Result<Trie, Hash> {
        Trie.deleteWithDB(trie, key, db);
    };

    public func hash(trie : Trie) : Hash = Trie.rootHash(trie);

    public func hashHex(trie : Trie) : Text = Trie.hashHex(trie);

    public func entries(trie : Trie, db : DB) : Iter<(Key, Value)> = Trie.toIterWithDB(trie, db);

    public func equal(a : Trie, b : Trie) : Bool = Trie.equal(a, b);

    public func toText(trie : Trie, db : DB) : Text = Trie.nodeToTextWithDB(trie, db);
};
