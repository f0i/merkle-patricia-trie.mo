import Arr "ArrayExtra";
import Array "mo:base/Array";
import Buffer "util/Buffer";
import Debug "mo:base/Debug";
import List "mo:base/List";
import Nibble "util/Nibble";
import Nat8 "mo:base/Nat8";
import Key "trie/Key";
import Text "mo:base/Text";

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
    value : ?Value;
    hash : Hash;
  };

  public type Leaf = {
    key : Key;
    value : Value;
    hash : Hash;
  };

  type Extension = {
    key : Key;
    node : Node; // TODO: rename to branch
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
    let { node; remaining; stack } = findPath(trie, key, null);
    let stuckOn = switch (stack) {
      case (null) {
        Debug.print("Stuck on root");
        trie;
      };
      case (?(n, _)) {
        switch (n) {
          case (#branch branch) { branch.nodes[Key.toIndex(remaining)] };
          case (_) { n };
        };
      };
    };
    Debug.print("stuckOn: " # nodeToText(stuckOn));

    // insert leaf
    var replacementNode : Node = switch (stuckOn) {
      case (#nul) { #leaf({ key = remaining; value = {}; hash = [] }) };
      case (#branch _) { Debug.trap("Can't get stuck on a branch") };
      case (#leaf leaf) {
        let matching = Key.matchingLength(leaf.key, remaining);

        // replace leaf with one of the following
        if (matching == 0) {
          // branch->leaf/new
          let newLeaf = createLeaf(Key.slice(remaining, 1), value);
          let oldLeaf = createLeaf(Key.slice(leaf.key, 1), leaf.value);
          createBranch(leaf.key, oldLeaf, remaining, newLeaf);
        } else if (matching == leaf.key.size()) {
          // extension->branch(leaf.value)->new
          let newLeaf = createLeaf(Key.slice(remaining, matching + 1), value);
          let newBranch = createBranchWithValue(Key.slice(remaining, matching), newLeaf, leaf.value);
          createExtension(leaf.key, newBranch);
        } else if (matching == remaining.size()) {
          // extension->branch(new.value)->leaf
          let oldLeaf = createLeaf(Key.slice(leaf.key, matching + 1), leaf.value);
          let newBranch = createBranchWithValue(Key.slice(remaining, matching), oldLeaf, value);
          createExtension(remaining, newBranch);
        } else {
          // extension->branch->leaf/new
          let newLeaf = createLeaf(Key.slice(remaining, matching + 1), value);
          let oldLeaf = createLeaf(Key.slice(leaf.key, matching + 1), leaf.value);
          let newBranch = createBranch(Key.slice(leaf.key, matching), oldLeaf, Key.slice(remaining, matching), newLeaf);
          createExtension(Key.take(remaining, matching), newBranch);
        };
      };
      case (#extension ext) {
        let matching = Key.matchingLength(ext.key, remaining);

        // replace extension with one of the following
        if (matching == 0) {
          // branch->ext/new
          let oldExt = createExtension(Key.slice(ext.key, 1), ext.node);
          let newLeaf = createLeaf(Key.slice(remaining, 1), value);
          createBranch(ext.key, oldExt, remaining, newLeaf);
        } else if (matching == ext.key.size()) {
          Debug.trap("Can't reach: if ext.key matches, it would have been followed");
        } else if (matching == remaining.size()) {
          // extension->branch(new.value)->ext
          let oldExt = createExtension(Key.slice(ext.key, matching + 1), ext.node);
          let newBranch = createBranchWithValue(Key.slice(ext.key, matching), oldExt, value);
          createExtension(remaining, newBranch);
        } else {
          // extension->branch->ext/new
          let oldExt = createExtension(Key.slice(ext.key, matching + 1), ext.node);
          let newLeaf = createLeaf(Key.slice(remaining, matching + 1), value);
          let newBranch = createBranch(Key.slice(ext.key, matching), oldExt, Key.slice(remaining, matching), newLeaf);
          createExtension(Key.take(remaining, matching), newBranch);
        };
      };
    };
    Debug.print("replacementNode: " # nodeToText(replacementNode));

    // insert replacement node and update nodes in path.stack
    var toUpdate = stack;
    while (true) {
      switch (toUpdate) {
        case (null) { return replacementNode };
        case (?(#branch branch, tail)) {
          Debug.trap("implement updateBranch");
          //replacementNode := updateBranch(#branch branch, index, replacementNode);
          toUpdate := tail;
        };
        case (?(#extension ext, tail)) {
          Debug.trap("implement updateExtension");
          //updateExtension(#extension ext, replacementNode);
          toUpdate := tail;
        };
        case (?(n, _)) {
          Debug.trap("in findPath: expected #branch or #extension but got " # nodeToText(n));
        };
      };
    };

    Debug.trap("unreachable (end of findPath)");
  };

  func createBranch(a : Key, nodeA : Node, b : Key, nodeB : Node) : Node {
    var nodes = Array.init<Node>(16, #nul);
    nodes[Key.toIndex(a)] := nodeA;
    nodes[Key.toIndex(b)] := nodeB;

    #branch {
      nodes = Array.freeze(nodes);
      value = null;
      hash = [];
    };
  };

  func createBranchWithValue(a : Key, nodeA : Node, value : Value) : Node {
    var nodes = Array.init<Node>(16, #nul);
    nodes[Key.toIndex(a)] := nodeA;

    #branch {
      nodes = Array.freeze(nodes);
      value = ?value;
      hash = [];
    };
  };

  func createLeaf(key : Key, value : Value) : Node {
    let hash : Hash = []; // TODO: implement
    return #leaf { key; value; hash };
  };

  func createExtension(key : Key, branch : Node) : Node {
    if (key == []) return branch;
    let hash : Hash = []; // TODO: implement
    return #extension { key; node = branch; hash };
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
      case (#branch(branch)) { branch.value };
      case (#leaf(leaf)) { ?leaf.value };
      case (#extension(ext)) { null };
    };
  };

  public type Path = {
    // The node for the given key or #nul if no node is set
    node : Node;
    // Branches and Extensions
    stack : List<Node>;
    // Part of the key not consumed by stack and node
    remaining : Key;
  };
  /// Find the a path in a node and return the path to get there.
  /// If no node was found at the given key, the part that exists will be
  /// returned as `stack` and the rest of the key will be returned as `remaining`.
  public func findPath(node : Node, key : Key, stack : List<Node>) : Path {
    // no key, return node and include it in stack unless it's #nul
    if (key == [] and node != #nul) {
      return { node; stack; remaining = [] };
    };

    let noMatch = {
      node = #nul;
      stack;
      remaining = key;
    };

    switch (node) {
      case (#nul) { return noMatch };
      case (#leaf leaf) {
        if (leaf.key == key) {
          // matchin leaf
          return {
            node = node;
            stack = stack;
            remaining = [];
          };
        };
        return { node = #nul; stack; remaining = key };
      };
      case (#branch branch) {
        let index = Key.toIndex(key);
        let path = findPath(branch.nodes[index], Key.slice(key, 1), ?(node, stack));
        return path;
      };
      case (#extension ext) {
        if (key.size() < ext.key.size()) {
          return noMatch;
        };

        let same = Nibble.matchingNibbleLength(key, ext.key);
        if (same < ext.key.size()) {
          return noMatch;
        };

        if (same == key.size()) {
          return {
            node = ext.node;
            stack = ?(node, stack);
            remaining = [];
          };
        };
        // extention is part of key
        return findPath(ext.node, Key.slice(key, same), ?(node, stack));
      };
    };
  };

  func serialize(node : Node) : [Buffer] {
    return []; //TODO: implement
  };

  public func nodeToText(node : Node) : Text {
    switch (node) {
      case (#nul) { "<>" };
      case (#branch(branch)) {
        let branches = Array.map(branch.nodes, nodeToText);
        "branch(" # Text.join(",", branches.vals()) # ")";
      };
      case (#leaf(leaf)) { "leaf(" # Key.toText(leaf.key) # ")" };
      case (#extension(ext)) {
        "extension(" # Key.toText(ext.key) # ": " # nodeToText(ext.node) # ")";
      };
    };
  };

  public func pathToText(path : Path) : Text {
    let nodes = List.toArray<Node>(path.stack);
    let nodesText = Array.map(nodes, nodeToText);
    "Path(\n" # //
    "  node: " # nodeToText(path.node) # "\n" # //
    "  stack: [\n    " # Text.join(",\n    ", nodesText.vals()) # "\n  ]" # //
    "  remaining: " # Key.toText(path.remaining) # "\n" # //
    ")";
  };
};
