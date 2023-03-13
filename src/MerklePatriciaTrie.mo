import Arr "ArrayExtra";
import Array "mo:base/Array";
import Buffer "util/Buffer";
import Debug "mo:base/Debug";
import List "mo:base/List";
import Nibble "util/Nibble";
import Nat8 "mo:base/Nat8";
import Key "trie/Key";

module {
  public type MerklePatriciaTrie = Node;
  public type Trie = Node;
  type Buffer = Buffer.Buffer;
  type Nibble = Nibble.Nibble;
  type List<T> = List.List<T>;

  public type Node = {
    #nul;
    #branch : Branch;
    #leaf : Leaf;
    #extension : Extension;
  };

  type Branch = {
    // 16 nodes
    nodes : [Node];
    value : Value;
    hash : Hash;
  };

  public type Leaf = {
    key : Key;
    value : Value;
    hash : Hash;
  };

  type Extension = {
    key : Key;
    node : Node;
    hash : Hash;
  };

  //TODO: implement
  public type Hash = Buffer;

  //TODO: implement
  type Value = {};

  /// Key describing a path in the trie
  /// In the case of ethereum this is keccak256(rlp(value))
  type Key = [Nibble];

  /// Key with prefix nibble indicating type and path length:
  /// prefix 0x00 estension, even
  /// prefix 0x1 estension, odd
  /// prefix 0x20 leaf, even
  /// prefix 0x3 leaf, odd
  /// This will always result in a even length, so it is save to convert into [Nat8]
  type EncodedKey = [Nibble];

  public func init() : Trie {
    #nul;
  };

  public func put(trie : Trie, key : Key, value : Value) : Trie {
    if (trie == #nul) {
      // Insert initial value
      let newNode : Node = #leaf({
        key;
        value = {};
        hash = [];
      });
      return newNode;
    };

    // Find closest node
    let { remaining; stack } = findPath(trie, key, null);
    let lastNode = switch (List.pop<Node>(stack)) {
      case ((?#nul, _)) {
        Debug.trap("Bug in Trie.put: lastNode should not be #nul here");
      };
      case ((?n, _)) { n };
      case (_) { Debug.trap("Bug in Trie.put: lastNode should exist here") };
    };

    Debug.print("implement put");
    return trie;
  };

  public func get(trie : Trie, key : Buffer) : ?Value {
    let path = findPath(trie, key, null);
    if (path.remaining.size() > 0) return null;
    return nodeValue(path.node);
  };

  public func del(trie : Trie, key : Buffer) : ?Buffer {
    Debug.trap("implement del");
  };

  func lookupNode(trie : Trie, node : Buffer) {

  };

  func allChildren(node : Node) : [Node] {
    Debug.trap("implement");
  };

  func encodeKey(key : Key, terminating : Bool) : EncodedKey {
    Nibble.compactEncode(key, terminating);
  };

  func nodeValue(node : Node) : ?Value {
    switch (node) {
      case (#nul) { null };
      case (#branch(branch)) { ?branch.value };
      case (#leaf(leaf)) { ?leaf.value };
      case (#extension(ext)) { null };
    };
  };

  public type Path = {
    node : Node;
    stack : List<Node>;
    remaining : Key;
    closest : ?Node;
  };
  /// Find the a path in a node and return the path to get there.
  /// If no node was found at the given key, the part that exists will be
  /// returned as `stack` and the rest of the key will be returned as `remaining`.
  public func findPath(node : Node, key : Key, stack : List<Node>) : Path {
    // no key, return node and include it in stack unless it's #nul
    if (key == [] and node != #nul) {
      return { node; stack = ?(node, stack); remaining = []; closest = ?node };
    };

    let noMatch = func(closest : Node) : Path {
      {
        node = #nul;
        stack;
        remaining = key;
        closest = ?closest;
      };
    };

    switch (node) {
      case (#nul) { return noMatch(#nul) };
      case (#leaf leaf) {
        if (leaf.key == key) {
          // matchin leaf
          return {
            node = node;
            stack = ?(node, stack);
            remaining = [];
            closest = null;
          };
        };
        return { node = #nul; stack; remaining = key; closest = ?node };
      };
      case (#branch branch) {
        let index = Key.toIndex(key);
        let path = findPath(branch.nodes[index], sliceKey(key, 1), ?(node, stack));
        return path;
      };
      case (#extension ext) {
        if (key.size() < ext.key.size()) {
          return noMatch(node);
        };

        let same = Nibble.matchingNibbleLength(key, ext.key);
        if (same < ext.key.size()) {
          return noMatch(node);
        };

        if (same == key.size()) {
          return {
            node;
            stack = ?(node, stack);
            remaining = [];
            closest = null;
          };
        };
        return findPath(ext.node, sliceKey(key, same), ?(node, stack));
      };
    };
  };

  func sliceKey(key : Key, n : Nat) : Key {
    let size = key.size();
    if (size < n) return [];
    Array.tabulate<Nibble>(size - n, func i = key[i + n]);
  };

  public func createLeaf(key : Key, value : Value) : Leaf {
    let hash : Hash = []; // TODO: implement
    return { key; value; hash };
  };

  func serialize(node : Node) : [Buffer] {
    return []; //TODO: implement
  };
};
