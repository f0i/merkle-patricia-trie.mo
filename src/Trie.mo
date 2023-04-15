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

    public type Trie = Trie.Trie;

    public func init() : Trie = Trie.init();

    public func put(trie : Trie, key : Key, value : Value) : Trie {
        Trie.put(trie, key, value);
    };

    public func get(trie : Trie, key : Key) : ?Value {
        Trie.get(trie, key);
    };

    public func delete(trie : Trie, key : Key) : Trie = Trie.delete(trie, key);

    public func hash(trie : Trie) : Hash = Trie.rootHash(trie);

    public func hashHex(trie : Trie) : Text = Trie.hashHex(trie);

    public func entries(trie : Trie) : Iter<(Key, Value)> = Trie.toIter(trie);

    public func equal(a : Trie, b : Trie) : Bool = Trie.equal(a, b);

    public func toText(trie : Trie) : Text = Trie.nodeToText(trie);
};
