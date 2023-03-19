import Arr "ArrayExtra";
import Array "mo:base/Array";
import Buffer "util/Buffer";
import Debug "mo:base/Debug";
import List "mo:base/List";
import Nibble "util/Nibble";
import Nat8 "mo:base/Nat8";
import Key "trie/Key";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import RLP "util/RLPHelper";
import Keccak "util/Keccak";
import Option "mo:base/Option";
import Hex "util/Hex";

module {
  public type MerklePatriciaTrie = Node;
  public type Trie = Node;
  type Buffer = Buffer.Buffer;
  type Nibble = Nibble.Nibble;
  type List<T> = List.List<T>;

  func print(msg : Text) {
    Debug.print(msg);
  };

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
  public type Value = Buffer;

  /// Key describing a path in the trie
  /// In the case of ethereum this is keccak256(rlp(value))
  public type Key = [Nibble];

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

  public func delete(trie : Trie, key : Key) : Trie {
    return put(trie, key, []); //TODO: implement
  };

  public func put(trie : Trie, key : Key, value : Value) : Trie {
    print("put(" # Key.toText(key) # " in " # nodeToText(trie) # ")");
    if (trie == #nul) {
      // Insert initial value
      let newNode : Node = #leaf({
        key;
        value;
        hash = [];
      });
      return newNode;
    };

    // Find closest node
    let path = findPath(trie, key, null);
    let { node; remaining; stack } = path;
    var update = false; // Flag indicating if a value is set already and should be updated instead

    let stuckOn = switch (node, stack) {
      case (#leaf _, _) { update := true; node }; // update existing leaf
      case (#branch _, _) { update := true; node }; // update existing branch value
      case (_, null) {
        print("Stuck on root");
        trie;
      };
      case (_, ?((k, n), _)) {
        switch (n) {
          case (#branch branch) {
            print("was in branch: " # nodeToText(n) # " with key " # Key.toText(k));
            branch.nodes[Key.toIndex(k)];
          };
          case (_) { n };
        };
      };
    };
    print("stuckOn: " # nodeToText(stuckOn) # " remaining: " # Key.toText(remaining) # " with " # pathToText(path));

    // insert leaf
    var replacementNode : Node = switch (stuckOn) {
      case (#nul) { createLeaf(remaining, value) };
      case (#branch branch) {
        // replace existing
        if (remaining != []) Debug.trap("Can't get stuck on a branch with non empty key: " # Key.toText(remaining));
        print("update branch value");
        updateBranchValue(branch, ?value);
      };
      case (#leaf leaf) {
        let matching = Key.matchingLength(leaf.key, remaining);

        // replace leaf with one of the following
        if (update) {
          // replace existing
          createLeaf(leaf.key, value);
        } else if (leaf.key == []) {
          // branch(leaf.value)->new
          let newLeaf = createLeaf(Key.slice(remaining, 1), value);
          createBranchWithValue(remaining, newLeaf, leaf.value);
        } else if (matching == 0) {
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
          let newBranch = createBranchWithValue(Key.slice(leaf.key, matching), oldLeaf, value);
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

        if (remaining == []) {
          // branch(value)->ext
          let oldExt = createExtension(Key.slice(ext.key, 1), ext.node);
          createBranchWithValue(ext.key, oldExt, value);
        } else if (matching == 0) {
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
    print("replacementNode: " # nodeToText(replacementNode));

    // insert replacement node and update nodes in path.stack
    var toUpdate = stack;

    while (true) {
      switch (toUpdate) {
        case (?((key, #branch branch), tail)) {
          replacementNode := updateBranch(branch, key, replacementNode); // TODO: check key
          toUpdate := tail;
        };
        case (?((key, #extension ext), tail)) {
          replacementNode := updateExtension(ext, replacementNode);
          toUpdate := tail;
        };
        case (?((k, n), _)) {
          Debug.trap("in findPath: expected #branch or #extension but got " # nodeToText(n) # " at " # Key.toText(k));
        };
        case (null) {
          print("trie.put: " # nodeToText(replacementNode));
          return replacementNode;
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

  func updateBranch(branch : Branch, key : Key, node : Node) : Node {
    var nodes = Array.thaw<Node>(branch.nodes);
    nodes[Key.toIndex(key)] := node;
    return #branch({
      nodes = Array.freeze(nodes);
      value = branch.value;
      hash = [];
    });
  };

  func updateBranchValue(branch : Branch, value : ?Value) : Node {
    return #branch({
      nodes = branch.nodes;
      value = value;
      hash = [];
    });
  };

  func updateExtension(ext : Extension, newNode : Node) : Node {
    return #extension {
      key = ext.key;
      node = newNode;
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
    Key.compactEncode(key, terminating);
  };

  func nodeValue(node : Node) : ?Value {
    switch (node) {
      case (#nul) { null };
      case (#branch(branch)) { branch.value };
      case (#leaf(leaf)) { ?leaf.value };
      case (#extension(ext)) { null };
    };
  };

  // Function `H(x)` where `x` is `RLP(node)` and `H(x) = keccak256(x) if len(x) >= 32 else x`
  func nodeHash(node : Node) : Hash {
    let serial = nodeSerialize(node);
    return hashIfLong(serial);
  };

  func nodeRaw(node : Node) : [Buffer] {
    switch (node) {
      case (#nul) { [] };
      case (#branch(branch)) {
        let raw = Array.init<Buffer>(17, []);
        for (i in Iter.range(0, 15)) {
          switch (branch.nodes[i]) {
            case (#nul) {};
            case (_) { raw[i] := nodeHash(branch.nodes[i]) };
          };
        };
        raw[16] := Option.get(branch.value, []);
        Array.freeze(raw);
      };
      case (#leaf(leaf)) {
        [Key.compactEncode(leaf.key, true), leaf.value];
      };
      case (#extension(ext)) {
        [Key.compactEncode(ext.key, false), nodeHash(ext.node)];
      };
    };
  };

  func nodeSerialize(node : Node) : Buffer {
    RLP.encodeOuter(nodeRaw(node));
  };

  func hashIfLong(data : Buffer) : Buffer {
    if (data.size() >= 32) {
      return Keccak.keccak(data);
    } else {
      return data;
    };
  };

  public func hash(trie : Trie) : Hash = nodeHash(trie);

  public func hashHex(trie : Trie) : Text {
    var bytes = nodeHash(trie);
    if (bytes.size() < 32) {
      bytes := Keccak.keccak(bytes);
    };
    return Hex.toText(bytes);
  };

  public type Path = {
    // The node for the given key or #nul if no node is set
    node : Node;
    // Branches and Extensions
    stack : List<(Key, Node)>;
    // Part of the key not consumed by stack and node
    remaining : Key;
  };
  /// Find the a path in a node and return the path to get there.
  /// If no node was found at the given key, the part that exists will be
  /// returned as `stack` and the rest of the key will be returned as `remaining`.
  public func findPath(node : Node, key : Key, stack : List<(Key, Node)>) : Path {
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
        let path = findPath(branch.nodes[index], Key.slice(key, 1), ?((key, node), stack));
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
            stack = ?((key, node), stack);
            remaining = [];
          };
        };
        // extention is part of key
        return findPath(ext.node, Key.slice(key, same), ?((key, node), stack));
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
        switch (branch.value) {
          case (null) {
            "branch(" # Text.join(",", branches.vals()) # ")";
          };
          case (?value) {
            "branchV(" # Text.join(",", branches.vals()) # " ; " # valueToText(value) # ")";
          };
        };
      };
      case (#leaf(leaf)) { "leaf(" # Key.toText(leaf.key) # ")" };
      case (#extension(ext)) {
        "extension(" # Key.toText(ext.key) # ": " # nodeToText(ext.node) # ")";
      };
    };
  };

  public func pathToText(path : Path) : Text {
    let nodeIter = List.toIter<(Key, Node)>(path.stack);
    func toText((k : Key, n : Node)) : Text = Key.toText(k) # ": " # nodeToText(n);
    let nodes = Iter.map<(Key, Node), Text>(nodeIter, toText);
    let nodesText = Iter.toArray(nodes);
    "Path(\n" # //
    "  node: " # nodeToText(path.node) # "\n" # //
    "  stack: [\n    " # Text.join(",\n    ", nodesText.vals()) # "\n  ]" # //
    "  remaining: " # Key.toText(path.remaining) # "\n" # //
    ")";
  };

  public func valueToText(value : Value) : Text {
    "{}";
  };
};
