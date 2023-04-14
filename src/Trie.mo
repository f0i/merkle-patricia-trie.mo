import Arr "util/ArrayExtra";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import List "mo:base/List";
import Nibble "util/Nibble";
import Nat8 "mo:base/Nat8";
import Key "Key";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import RLP "util/RLPHelper";
import Keccak "util/Keccak";
import Option "mo:base/Option";
import Hex "util/Hex";
import TrieMap "mo:base/TrieMap";
import Nat32 "mo:base/Nat32";
import Int "mo:base/Int";
import Value "Value";
import Hash "Hash";
import Blob "mo:base/Blob";

/// Data structure and functions to manipulate and query a Merkle Patricia Trie.
module {
  public type Trie = Node;
  type Value = Value.Value;
  type RlpEncoded = [Nat8];
  type Nibble = Nibble.Nibble;
  type List<T> = List.List<T>;
  type TrieMap = TrieMap.TrieMap<Hash, Node>;
  type Result<T, E> = Result.Result<T, E>;

  /// A Node object
  public type Node = {
    #nul;
    #branch : Branch;
    #leaf : Leaf;
    #extension : Extension;
    #hash : Hash;
  };

  /// A Branch node
  public type Branch = {
    // 16 nodes
    nodes : [Node];
    value : ?Value;
    var hash : ?Hash;
  };

  /// A Leaf node
  public type Leaf = {
    key : Key;
    value : Value;
    var hash : ?Hash;
  };

  /// An Extension node
  public type Extension = {
    key : Key;
    node : Node;
    var hash : ?Hash;
  };

  /// A Hash value
  type Hash = Hash.Hash;

  /// Key describing a path in the trie
  /// In the case of ethereum this is keccak256(rlp(value))
  type Key = Key.Key;

  /// Key with prefix nibble indicating type and path length:
  /// prefix 0x00 extension, even
  /// prefix 0x1 extension, odd
  /// prefix 0x20 leaf, even
  /// prefix 0x3 leaf, odd
  /// This will always result in a even length, so it is save to convert into [Nat8]
  type EncodedKey = [Nibble];

  /// Create an empty trie
  public func init() : Trie {
    #nul;
  };

  /// Deserialize RLP encoded node
  public func nodeDecode(rlpData : [Nat8]) : Node {
    let data = RLP.decode(rlpData);

    switch (data) {
      case (#ok(value)) {
        if (value == []) return #nul;
        if (value.size() == 17) return rawToBranch(value);
        if (value.size() == 2) {
          let compactKey = switch (RLP.decodeValue(value[0])) {
            case (#ok(value)) { value };
            case (#err(msg)) {
              return #nul;
            }; // ignore invalid encoded values
          };
          let { key; terminating } = Key.compactDecode(compactKey);
          let hashOrValue : Blob = switch (RLP.decodeValue(value[1])) {
            case (#ok(value)) { value };
            case (#err(msg)) {
              return #nul;
            }; // ignore invalid encoded values
          };
          if (terminating) {
            return createLeaf(key, hashOrValue);
          } else {
            return createExtension(key, #hash(hashOrValue));
          };
        };
        // invalid data will be ignored (return #nul)
        return #nul;
      };
      case (#err(msg)) {
        Debug.print("Trie.nodeDecode error: " # msg);
        return #nul;
      };
    };
  };

  /// Convert raw values into a branch node
  /// `raw` must contain 17 elements
  func rawToBranch(raw : [[Nat8]]) : Node {
    assert raw.size() == 17;

    var nodes = Array.init<Node>(16, #nul);

    for (i in Iter.range(0, 15)) {
      if (raw[i].size() >= 32) {
        switch (RLP.decodeValue(raw[i])) {
          case (#ok(value)) { nodes[i] := #hash(value) };
          case (#err(msg)) {
            Debug.print("Trie.rawToBranch: error decoding node " # msg);
            return #nul;
          };
        };
      } else {
        // RLP encoded node
        // TODO: should this be decoded or used as a hash?
        // currently it is used as a hash and requires an separate lookup
        // this will reduce computation overhead if proof is not verified,
        // but might require more lookups when verifying, potentially: TODO: performance test?
        nodes[i] := #hash(Blob.fromArray(raw[i]));
      };
    };

    let value : Value = switch (RLP.decodeValue(raw[16])) {
      case (#ok(value)) { value };
      case (#err(msg)) {
        Debug.print("rawToBranch: error decoding value " # msg);
        return #nul;
      };
    };

    let branch : Branch = {
      nodes = Array.freeze(nodes);
      value : ?Value = ?value;
      var hash : ?Hash = null;
    };
    return #branch(branch);
  };

  /// Delete a key from a trie
  public func delete(trie : Trie, key : Key) : Trie {
    return put(trie, key, Value.empty);
  };

  /// Delete a key from a trie
  /// Similar to  the `delete` function, but uses a DB to store hash/Node pairs
  /// This should not be mixed with `put` or `delete` function or it can cause invalid tries or traps!
  public func deleteWithDB(trie : Trie, key : Key, db : DB) : Result<Trie, Hash> {
    return putWithDB(trie, key, Value.empty, db);
  };

  /// Add a value into a trie
  /// If value is empty, the key will be deleted
  public func put(trie : Trie, key : Key, value : Value) : Trie {

    // Find closest node
    let path = findPath(trie, key, null);
    let { node; remaining; stack; mismatch } = path;
    let delete = value == Value.empty;

    let (stuckOn, update) = switch (node, mismatch) {
      case (#leaf _, _) { (node, true) }; // update existing leaf
      case (#branch _, _) { (node, true) }; // update existing branch value
      case (_, mismatch) {
        if (delete) { return trie }; // Key is not in trie, nothing to delete
        (mismatch, false);
      };
    };

    // insert leaf
    var replacementNode : Node = switch (stuckOn) {
      case (#nul) { createLeaf(remaining, value) };
      case (#hash(hash)) {
        Debug.trap("Trie.put: stuck on #hash-node. This can never happen on a full trie created only by using the Trie.put function!");
      };
      case (#branch branch) {
        // replace existing
        if (remaining != []) Debug.trap("Can't get stuck on a branch with non empty key: " # Key.toText(remaining));
        if (delete) {
          updateBranchValue(branch, null);
        } else {
          updateBranchValue(branch, ?value);
        };
      };
      case (#leaf leaf) {
        let matching = Key.matchingLength(leaf.key, remaining);

        // replace leaf with one of the following
        if (update) {
          // replace existing
          if (delete) {
            #nul;
          } else {
            createLeaf(leaf.key, value);
          };
        } else if (leaf.key == []) {
          // branch(leaf.value)->new
          let newLeaf = createLeaf(Key.drop(remaining, 1), value);
          createBranchWithValue(remaining, newLeaf, leaf.value);
        } else if (remaining == []) {
          // branch(new.value)->leaf
          let oldLeaf = createLeaf(Key.drop(leaf.key, 1), leaf.value);
          createBranchWithValue(leaf.key, oldLeaf, value);
        } else if (matching == 0) {
          // branch->leaf/new
          let newLeaf = createLeaf(Key.drop(remaining, 1), value);
          let oldLeaf = createLeaf(Key.drop(leaf.key, 1), leaf.value);
          createBranch(leaf.key, oldLeaf, remaining, newLeaf);
        } else if (matching == leaf.key.size()) {
          // extension->branch(leaf.value)->new
          let newLeaf = createLeaf(Key.drop(remaining, matching + 1), value);
          let newBranch = createBranchWithValue(Key.drop(remaining, matching), newLeaf, leaf.value);
          createExtension(leaf.key, newBranch);
        } else if (matching == remaining.size()) {
          // extension->branch(new.value)->leaf
          let oldLeaf = createLeaf(Key.drop(leaf.key, matching + 1), leaf.value);
          let newBranch = createBranchWithValue(Key.drop(leaf.key, matching), oldLeaf, value);
          createExtension(remaining, newBranch);
        } else {
          // extension->branch->leaf/new
          let newLeaf = createLeaf(Key.drop(remaining, matching + 1), value);
          let oldLeaf = createLeaf(Key.drop(leaf.key, matching + 1), leaf.value);
          let newBranch = createBranch(Key.drop(leaf.key, matching), oldLeaf, Key.drop(remaining, matching), newLeaf);
          createExtension(Key.take(remaining, matching), newBranch);
        };
      };
      case (#extension ext) {
        let matching = Key.matchingLength(ext.key, remaining);

        if (remaining == []) {
          // branch(value)->ext
          let oldExt = createExtension(Key.drop(ext.key, 1), ext.node);
          createBranchWithValue(ext.key, oldExt, value);
        } else if (matching == 0) {
          // branch->ext/new
          let oldExt = createExtension(Key.drop(ext.key, 1), ext.node);
          let newLeaf = createLeaf(Key.drop(remaining, 1), value);
          createBranch(ext.key, oldExt, remaining, newLeaf);
        } else if (matching == ext.key.size()) {
          Debug.trap("Can't reach: if ext.key matches, it would have been followed");
        } else if (matching == remaining.size()) {
          // extension->branch(new.value)->ext
          let oldExt = createExtension(Key.drop(ext.key, matching + 1), ext.node);
          let newBranch = createBranchWithValue(Key.drop(ext.key, matching), oldExt, value);
          createExtension(remaining, newBranch);
        } else {
          // extension->branch->ext/new
          let oldExt = createExtension(Key.drop(ext.key, matching + 1), ext.node);
          let newLeaf = createLeaf(Key.drop(remaining, matching + 1), value);
          let newBranch = createBranch(Key.drop(ext.key, matching), oldExt, Key.drop(remaining, matching), newLeaf);
          createExtension(Key.take(remaining, matching), newBranch);
        };
      };
    };

    // insert replacement node and update nodes in path.stack
    var toUpdate = stack;

    while (true) {
      switch (toUpdate) {
        case (?((key, #branch branch), tail)) {
          assert key != [];
          replacementNode := updateBranch(branch, key, replacementNode);
          toUpdate := tail;
        };
        case (?((key, #extension ext), tail)) {
          replacementNode := updateExtension(ext, replacementNode);
          toUpdate := tail;
        };
        case (?((k, n), _)) {
          Debug.trap("Trie.put: expected findPath.stack to only contain #branch or #extension but got " # nodeToText(n) # " at " # Key.toText(k));
        };
        case (null) {
          return replacementNode;
        };
      };
    };

    Debug.trap("unreachable (end of Trie.put)");
  };

  /// Create a new branch with two nodes
  func createBranch(a : Key, nodeA : Node, b : Key, nodeB : Node) : Node {
    var nodes = Array.init<Node>(16, #nul);
    let indexA = Key.toIndex(a);
    let indexB = Key.toIndex(b);
    nodes[indexA] := nodeA;
    nodes[indexB] := nodeB;

    #branch {
      nodes = Array.freeze(nodes);
      value = null;
      var hash = null;
    };
  };

  /// Create a new branch with a single node and a value
  func createBranchWithValue(a : Key, nodeA : Node, value : Value) : Node {
    var nodes = Array.init<Node>(16, #nul);
    nodes[Key.toIndex(a)] := nodeA;

    #branch {
      nodes = Array.freeze(nodes);
      value = ?value;
      var hash = null;
    };
  };

  /// Change one node inside an existing branch
  func updateBranch(branch : Branch, key : Key, node : Node) : Node {
    var nodes = Array.thaw<Node>(branch.nodes);
    nodes[Key.toIndex(key)] := node;
    let newBranch : Branch = {
      nodes = Array.freeze(nodes);
      value = branch.value;
      var hash = null;
    };
    if (isEmpty(node)) {
      return simplifyBranch(newBranch);
    };

    return #branch(newBranch);
  };

  func updateBranchWithDB(branch : Branch, key : Key, node : Node, db : DB) : Result<Node, Hash> {
    var nodes = Array.thaw<Node>(branch.nodes);
    nodes[Key.toIndex(key)] := node;
    let newBranch : Branch = {
      nodes = Array.freeze(nodes);
      value = branch.value;
      var hash = null;
    };
    if (isEmpty(node)) {
      return simplifyBranchWithDB(newBranch, db);
    } else {
      return #ok(#branch(newBranch));
    };
  };

  func simplifyBranch(branch : Branch) : Node {
    var values = 0;
    var index = 0;
    if (branch.value != null) {
      values += 1;
    };
    for (i in Iter.range(0, 15)) {
      if (not isEmpty(branch.nodes[i])) {
        values += 1;
        index := i;
      };

      // Check if at least two values are set
      if (values > 1) return #branch(branch);
    };

    // no value set
    if (values == 0) return #nul;

    // only one value set
    switch (branch.value) {
      case (?value) {
        return createLeaf(Key.fromKeyBytes([]), value);
      };
      case (null) {
        return addKeyPrefix(branch.nodes[index], Nibble.fromNat(index));
      };
    };
  };

  func simplifyBranchWithDB(branch : Branch, db : DB) : Result<Node, Hash> {
    var values = 0;
    var index = 0;
    if (branch.value != null) {
      values += 1;
    };
    for (i in Iter.range(0, 15)) {
      if (not isEmpty(branch.nodes[i])) {
        values += 1;
        index := i;
      };

      // Check if at least two values are set
      if (values > 1) return #ok(#branch(branch));
    };

    // no value set
    if (values == 0) return #ok(#nul);

    // only one value set
    switch (branch.value) {
      case (?value) {
        return #ok(createLeaf(Key.fromKeyBytes([]), value));
      };
      case (null) {
        switch (resolveWithDB(branch.nodes[index], db)) {
          case (#ok(node)) {
            return #ok(addKeyPrefix(node, Nibble.fromNat(index)));
          };
          case (#err hash) {
            return #err(hash);
          };
        };
      };
    };
  };

  /// Get a node from the database
  /// Returns the node parameter if it is not a #hash
  /// Returns the hash if it could not be found in the database
  func resolveWithDB(node : Node, db : DB) : Result<Node, Hash> {
    switch (node) {
      case (#hash hash) {
        switch (db.get(hash)) {
          case (?val) { #ok val };
          case (null) { #err hash };
        };
      };
      case (_) { #ok(node) };
    };
  };

  /// Add a nibble in front of the nodes key
  func addKeyPrefix(node : Node, index : Nibble) : Node {
    switch (node) {
      case (#nul) { #nul };
      case (#branch(branch)) { createExtension([index], node) };
      case (#leaf(leaf)) {
        createLeaf(Key.addPrefix(index, leaf.key), leaf.value);
      };
      case (#extension(ext)) {
        createExtension(Key.addPrefix(index, ext.key), ext.node);
      };
      case (#hash hash) {
        Debug.trap("unexpected hash in addLeyPrefix");
        createBranch([index], node, [index], node);
      };
    };
  };

  /// Change the value for a branch
  func updateBranchValue(branch : Branch, value : ?Value) : Node {
    let newBranch : Branch = {
      nodes = branch.nodes;
      value = value;
      var hash = null;
    };
    switch (value) {
      case (?value) #branch(newBranch);
      case (null) simplifyBranch(newBranch);
    };
  };

  func updateBranchValueWithDB(branch : Branch, value : ?Value, db : DB) : Result<Node, Hash> {
    let newBranch : Branch = {
      nodes = branch.nodes;
      value = value;
      var hash = null;
    };
    switch (value) {
      case (?value) #ok(#branch(newBranch));
      case (null) simplifyBranchWithDB(newBranch, db);
    };
  };

  /// Change the node an extension is pointing to
  func updateExtension(ext : Extension, newNode : Node) : Node {
    switch (newNode) {
      case (#nul) { #nul };
      case (#branch(branch)) {
        #extension {
          key = ext.key;
          node = newNode;
          var hash = null;
        };

      };
      case (#leaf(leaf)) {
        let key = Key.join(ext.key, leaf.key);
        createLeaf(key, leaf.value);
      };
      case (#extension(other)) {
        let key = Key.join(ext.key, other.key);
        createExtension(key, other.node);
      };
      case (#hash hash) {
        Debug.print("Trie.updateExtension: unexpected #hash " # Hash.toHex(hash));
        #extension {
          key = ext.key;
          node = newNode;
          var hash = null;
        };
      };
    };
  };

  /// Change the node an extension is pointing to
  func updateExtensionWithDB(ext : Extension, newNode : Node, db : DB) : Result<Node, Hash> {
    switch (resolveWithDB(newNode, db)) {
      case (#ok node) { #ok(updateExtension(ext, node)) };
      case (#err hash) { #err hash };
    };
  };

  /// Create a leaf node
  public func createLeaf(key : Key, value : Value) : Node {
    return #leaf { key; value; var hash = null };
  };

  /// Create an extension node
  func createExtension(key : Key, branch : Node) : Node {
    if (key == []) return branch;
    return #extension { key; node = branch; var hash = null };
  };

  /// Get the value for a specific key
  public func get(trie : Trie, key : Key) : ?Value {
    let path = findPath(trie, key, null);
    if (path.remaining.size() > 0) return null;
    return nodeValue(path.node);
  };

  /// Get the value for a specific key
  public func getWithDB(trie : Trie, key : Key, db : DB) : Result<?Value, Text> {
    let path = findPathWithDB(trie, key, null, db);
    switch (path.node) {
      case (#hash hash) {
        return #err("Trie.getWithDB: Missing hash " # Hash.toHex(hash));
      };
      case (_) {
        if (path.remaining.size() > 0) return #ok(null);
        return #ok(nodeValue(path.node));
      };
    };
  };

  /// return the value of a node or null if no value is set
  public func nodeValue(node : Node) : ?Value {
    switch (node) {
      case (#nul) { null };
      case (#branch(branch)) { branch.value };
      case (#leaf(leaf)) { ?leaf.value };
      case (#extension(ext)) { null };
      case (#hash hash) { null };
    };
  };

  /// Function `H(x)` where `x` is `RLP(node)` and `H(x) = keccak256(x) if len(x) >= 32 else x`
  public func nodeHash(node : Node) : Hash {
    switch (node) {
      case (#hash(hash)) { return hash };
      case (#branch(branch)) {
        switch (branch.hash) {
          case (null) {
            let serial = nodeSerialize(node);
            let hash = hashIfLong(Blob.fromArray(serial));
            branch.hash := ?hash;
            return hash;
          };
          case (?hash) { return hash };
        };
      };
      case (#leaf(leaf)) {
        switch (leaf.hash) {
          case (null) {
            let serial = nodeSerialize(node);
            let hash = hashIfLong(Blob.fromArray(serial));
            leaf.hash := ?hash;
            return hash;
          };
          case (?hash) { return hash };
        };
      };
      case (#extension(ext)) {
        switch (ext.hash) {
          case (null) {
            let serial = nodeSerialize(node);
            let hash = hashIfLong(Blob.fromArray(serial));
            ext.hash := ?hash;
            return hash;

          };
          case (?hash) { return hash };
        };
      };
      case (#nul) {
        return Hash.empty;
      };
    };
  };

  /// Get an array of encoded elements
  func nodeRaw(node : Node) : [[Nat8]] {
    switch (node) {
      case (#nul) { [] };
      case (#hash(hash)) {
        [RLP.encodeHash(hash)];
      };
      case (#branch(branch)) {
        let raw = Array.init<[Nat8]>(17, [0x80]);
        for (i in Iter.range(0, 15)) {
          switch (branch.nodes[i]) {
            case (#nul) {};
            case (_) { raw[i] := RLP.encodeHash(nodeHash(branch.nodes[i])) };
          };
        };
        raw[16] := RLP.encodeValue(Option.get<Value>(branch.value, ""));
        Array.freeze(raw);
      };
      case (#leaf(leaf)) {
        RLP.encodeEach([Key.compactEncode(leaf.key, true), Value.toArray(leaf.value)]);
      };
      case (#extension(ext)) {
        ([RLP.encode(Key.compactEncode(ext.key, false)), RLP.encodeHash(nodeHash(ext.node))]);
      };
    };
  };

  /// RLP encode a Node
  public func nodeSerialize(node : Node) : [Nat8] {
    let raw = nodeRaw(node);
    if (raw.size() == 1) {
      // value or hash
      return raw[0];
    } else {
      RLP.encodeOuter(nodeRaw(node));
    };
  };

  func hashIfLong(data : Hash) : Hash {
    if (data.size() >= 32) {
      return Keccak.keccak(Hash.toArray(data));
    } else {
      return data;
    };
  };

  /// Get a root hash of a Trie
  public func rootHash(trie : Trie) : Hash {
    var bytes : Hash = nodeHash(trie);
    if (bytes.size() < 32) {
      bytes := Keccak.keccak(Hash.toArray(bytes));
    };
    return bytes;
  };

  /// Get root hash as a hex Text
  public func hashHex(trie : Trie) : Text {
    return Hash.toHex(rootHash(trie));
  };

  /// Internal information from querying a trie
  public type Path = {
    // The node for the given key or #nul if no node is set
    node : Node;
    // Branches and Extensions
    stack : List<(Key, Node)>;
    // Part of the key not consumed by stack and node
    remaining : Key;
    // first mismatch
    mismatch : Node;
  };
  /// Find the a path in a node and return the path to get there.
  /// If no node was found at the given key, the part that exists will be
  /// returned as `stack` and the rest of the key will be returned as `remaining`.
  public func findPath(node : Node, key : Key, stack : List<(Key, Node)>) : Path {
    // no key, return node and include it in stack unless it's #nul

    func noMatch(mismatch : Node) : Path = {
      node = #nul;
      stack;
      remaining = key;
      mismatch;
    };

    switch (node) {
      case (#nul) { return noMatch(#nul) };
      case (#hash hash) {
        return { node; stack; remaining = key; mismatch = #nul };
      };
      case (#leaf leaf) {
        if (leaf.key == key) {
          // matching leaf
          return {
            node = node;
            stack = stack;
            remaining = [];
            mismatch = #nul;
          };
        };
        return { node = #nul; stack; remaining = key; mismatch = #leaf(leaf) };
      };
      case (#branch branch) {
        if (key == []) {
          return { node; stack; remaining = []; mismatch = #nul };
        };
        let index = Key.toIndex(key);
        let path = findPath(branch.nodes[index], Key.drop(key, 1), ?((key, node), stack));
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
            node = ext.node;
            stack = ?((key, node), stack);
            remaining = [];
            mismatch = #nul;
          };
        };
        // extention is part of key
        return findPath(ext.node, Key.drop(key, same), ?((key, node), stack));
      };
    };
  };

  /// Find the a path in a node and return the path to get there.
  /// Similar to `findPath`, but also looks up nodes in a DB
  public func findPathWithDB(node : Node, key : Key, stack : List<(Key, Node)>, db : DB) : Path {
    var path = findPath(node, key, stack);

    switch (path) {
      case ({ node = #hash(hash); remaining; stack }) {
        switch (db.get(hash)) {
          case (?node) { return findPathWithDB(node, remaining, stack, db) };
          case (null) {
            return path;
          };
        };
      };
      case (_) {
        return path;
      };
    };
  };

  /// Get an Iter to get all Key/Value pairs
  /// This should only be called on a tree build with `put` (not `putWithDB`),
  /// otherwise it can cause a trap!
  public func toIter(trie : Trie) : Iter.Iter<(Key, Value)> {
    type StackElement = { key : Key; node : Node };

    object {
      var stack : List.List<StackElement> = ?({ key = []; node = trie }, null);

      public func next() : ?(Key, Value) {
        switch (stack) {
          case (null) { return null };
          case (?(n, tail)) {
            switch (n.node) {
              case (#hash(hash)) { Debug.trap("Trie.toIter: incomplete trie") };
              case (#nul) {
                // ignore null
                stack := tail;
                return next();
              };
              case (#extension(ext)) {
                // replace extension on the stack with the branch it points to
                let newKey = Key.join(n.key, ext.key);
                stack := ?({ key = newKey; node = ext.node }, tail);
                return next();
              };
              case (#leaf(leaf)) {
                // leaf will return the value
                stack := tail;
                return ?(Key.join(n.key, leaf.key), leaf.value);
              };
              case (#branch(branch)) {
                // add each node to the stack, if branch has a value return it
                stack := tail;
                for (i in Iter.revRange(15, 0)) {
                  let index = Int.abs(i);
                  switch (branch.nodes[index]) {
                    case (#nul) {};
                    case (_) {
                      stack := ?(
                        {
                          key = Key.append(n.key, Nat8.fromNat(index));
                          node = branch.nodes[index];
                        },
                        stack,
                      );
                    };
                  };
                };
                switch (branch.value) {
                  case (?value) {
                    return ?(n.key, value);
                  };
                  case (null) { return next() };
                };
              };
            };
          };
        };
      };
    };
  };

  /// Get an Iter to get all Key/Value pairs
  /// Hashes that can't be resolved with the database will be ignored
  public func toIterWithDB(trie : Trie, db : DB) : Iter.Iter<(Key, Value)> {
    type StackElement = { key : Key; node : Node };

    object {
      var stack : List.List<StackElement> = ?({ key = []; node = trie }, null);

      public func next() : ?(Key, Value) {
        switch (stack) {
          case (null) { return null };
          case (?(n, tail)) {
            switch (n.node) {
              case (#hash(hash)) {
                switch (db.get(hash)) {
                  case (?node) {
                    stack := ?({ key = n.key; node }, stack);
                  };
                  case (null) {
                    Debug.print("Trie.toIterWithDB: missing hash " # Hash.toHex(hash));
                  };
                };
                return next();
              };
              case (#nul) {
                // ignore null
                stack := tail;
                return next();
              };
              case (#extension(ext)) {
                // replace extension on the stack with the branch it points to
                let newKey = Key.join(n.key, ext.key);
                stack := ?({ key = newKey; node = ext.node }, tail);
                return next();
              };
              case (#leaf(leaf)) {
                // leaf will return the value
                stack := tail;
                return ?(Key.join(n.key, leaf.key), leaf.value);
              };
              case (#branch(branch)) {
                // add each node to the stack, if branch has a value return it
                stack := tail;
                for (i in Iter.revRange(15, 0)) {
                  let index = Int.abs(i);
                  switch (branch.nodes[index]) {
                    case (#nul) {};
                    case (_) {
                      stack := ?(
                        {
                          key = Key.append(n.key, Nat8.fromNat(index));
                          node = branch.nodes[index];
                        },
                        stack,
                      );
                    };
                  };
                };
                switch (branch.value) {
                  case (?value) {
                    return ?(n.key, value);
                  };
                  case (null) { return next() };
                };
              };
            };
          };
        };
      };
    };
  };

  /// Check if a Trie is empty
  public func isEmpty(trie : Trie) : Bool {
    switch (trie) {
      case (#nul) { true };
      case (#hash hash) { hash == Hash.empty };
      case (_) { false };
    };
  };

  /// Check if Node `a` is equal to Node `b`
  public func nodeEqual(a : Node, b : Node) : Bool {
    switch (a, b) {
      case (#nul, #nul) { true };
      case (#hash(_), _) { nodeHash(a) == nodeHash(b) };
      case (_, #hash(_)) { nodeHash(a) == nodeHash(b) };
      case (#branch(a), #branch(b)) {
        for (i in Iter.range(0, 15)) {
          if (not nodeEqual(a.nodes[i], b.nodes[i])) return false;
        };
        a.value == b.value;
      };
      case (#extension(a), #extension(b)) {
        a.key == b.key and nodeEqual(a.node, b.node)
      };
      case (#leaf(a), #leaf(b)) { a.key == b.key and a.value == b.value };
      case (_, _) { false };
    };
  };

  /// Check if Trie `a` is equal to Trie `b`
  public func equal(a : Trie, b : Trie) : Bool = nodeEqual(a, b);

  /// Get a node as a human readable Text
  public func nodeToText(node : Node) : Text {
    switch (node) {
      case (#nul) { "<>" };
      case (#hash(hash)) { "Hash" # Hash.toHex(hash) };
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
      case (#leaf(leaf)) {
        "leaf(" # Key.toText(leaf.key) # ", {" # Value.toHex(leaf.value) # "})";
      };
      case (#extension(ext)) {
        "extension(" # Key.toText(ext.key) # ": " # nodeToText(ext.node) # ")";
      };
    };
  };

  public func nodeToTextWithDB(node : Node, db : DB) : Text {
    switch (node) {
      case (#nul) { "<>" };
      case (#hash(hash)) {
        switch (db.get(hash)) {
          case (?node) { nodeToTextWithDB(node, db) };
          case (null) { "Hash" # Hash.toHex(hash) };
        };
      };
      case (#branch(branch)) {
        let branches = Array.map(branch.nodes, func(n : Node) : Text = nodeToTextWithDB(n, db));
        switch (branch.value) {
          case (null) {
            "branch(" # Text.join(",", branches.vals()) # ")";
          };
          case (?value) {
            "branchV(" # Text.join(",", branches.vals()) # " ; " # valueToText(value) # ")";
          };
        };
      };
      case (#leaf(leaf)) {
        "leaf(" # Key.toText(leaf.key) # ", {" # Value.toHex(leaf.value) # "})";
      };
      case (#extension(ext)) {
        "extension(" # Key.toText(ext.key) # ": " # nodeToTextWithDB(ext.node, db) # ")";
      };
    };
  };

  /// Get path info as a human readable Text
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

  /// Get placeholder text for any value
  public func valueToText(value : Value) : Text {
    "{" # Value.toHex(value) # "}";
  };

  /// Interface for a database
  public type DB = {
    put : (Hash, Node) -> ();
    get : Hash -> ?Node;
  };

  /// Add a value into a trie
  /// Similar to  the `put` function, but uses a DB to store hash/Node pairs
  /// This should not be mixed with `put` or `delete` function or it can cause invalid tries or traps!
  public func putWithDB(trie : Trie, key : Key, value : Value, db : DB) : Result<Trie, Hash> {
    let path = findPathWithDB(trie, key, null, db);

    let { node; remaining; stack; mismatch } = path;
    let delete = value == Value.empty;

    let (stuckOn, update) = switch (node, mismatch) {
      case (#leaf _, _) { (node, true) }; // update existing leaf
      case (#branch _, _) { (node, true) }; // update existing branch value
      case (#hash hash, _) {
        return #err(hash);
      };
      case (_, mismatch) { (mismatch, false) };
    };

    var replacementNode : Node = switch (stuckOn) {
      case (#nul) { createLeaf(remaining, value) };
      case (#hash(hash)) { Debug.trap("Case #hash(_) already handled above") };
      case (#branch branch) {
        // replace existing
        if (remaining != []) Debug.trap("Can't get stuck on a branch with non empty key: " # Key.toText(remaining));
        let res = updateBranchValueWithDB(branch, (if (delete) null else ?value), db);
        switch (res) {
          case (#ok(node)) node;
          case (#err(hash)) return #err(hash);
        };
      };
      case (#leaf leaf) {
        let matching = Key.matchingLength(leaf.key, remaining);

        // replace leaf with one of the following
        if (update) {
          // replace existing
          if (delete) {
            #nul;
          } else {
            createLeaf(leaf.key, value);
          };
        } else if (leaf.key == []) {
          // branch(leaf.value)->new
          let newLeaf = createLeaf(Key.drop(remaining, 1), value);
          createBranchWithValue(remaining, newLeaf, leaf.value);
        } else if (remaining == []) {
          // branch(new.value)->leaf
          let oldLeaf = createLeaf(Key.drop(leaf.key, 1), leaf.value);
          createBranchWithValue(leaf.key, oldLeaf, value);
        } else if (matching == 0) {
          // branch->leaf/new
          let newLeaf = createLeaf(Key.drop(remaining, 1), value);
          let oldLeaf = createLeaf(Key.drop(leaf.key, 1), leaf.value);
          createBranch(leaf.key, oldLeaf, remaining, newLeaf);
        } else if (matching == leaf.key.size()) {
          // extension->branch(leaf.value)->new
          let newLeaf = createLeaf(Key.drop(remaining, matching + 1), value);
          let newBranch = createBranchWithValue(Key.drop(remaining, matching), newLeaf, leaf.value);
          createExtension(leaf.key, newBranch);
        } else if (matching == remaining.size()) {
          // extension->branch(new.value)->leaf
          let oldLeaf = createLeaf(Key.drop(leaf.key, matching + 1), leaf.value);
          let newBranch = createBranchWithValue(Key.drop(leaf.key, matching), oldLeaf, value);
          createExtension(remaining, newBranch);
        } else {
          // extension->branch->leaf/new
          let newLeaf = createLeaf(Key.drop(remaining, matching + 1), value);
          let oldLeaf = createLeaf(Key.drop(leaf.key, matching + 1), leaf.value);
          let newBranch = createBranch(Key.drop(leaf.key, matching), oldLeaf, Key.drop(remaining, matching), newLeaf);
          createExtension(Key.take(remaining, matching), newBranch);
        };
      };
      case (#extension ext) {
        let matching = Key.matchingLength(ext.key, remaining);

        if (remaining == []) {
          // branch(value)->ext
          let oldExt = createExtension(Key.drop(ext.key, 1), ext.node);
          createBranchWithValue(ext.key, oldExt, value);
        } else if (matching == 0) {
          // branch->ext/new
          let oldExt = createExtension(Key.drop(ext.key, 1), ext.node);
          let newLeaf = createLeaf(Key.drop(remaining, 1), value);
          createBranch(ext.key, oldExt, remaining, newLeaf);
        } else if (matching == ext.key.size()) {
          Debug.trap("Can't reach: if ext.key matches, it would have been followed");
        } else if (matching == remaining.size()) {
          // extension->branch(new.value)->ext
          let oldExt = createExtension(Key.drop(ext.key, matching + 1), ext.node);
          let newBranch = createBranchWithValue(Key.drop(ext.key, matching), oldExt, value);
          createExtension(remaining, newBranch);
        } else {
          // extension->branch->ext/new
          let oldExt = createExtension(Key.drop(ext.key, matching + 1), ext.node);
          let newLeaf = createLeaf(Key.drop(remaining, matching + 1), value);
          let newBranch = createBranch(Key.drop(ext.key, matching), oldExt, Key.drop(remaining, matching), newLeaf);
          createExtension(Key.take(remaining, matching), newBranch);
        };
      };
    };

    // insert replacement node and update nodes in path.stack
    var toUpdate = stack;
    var hash = nodeHash(replacementNode);
    db.put(hash, replacementNode);
    replacementNode := #hash hash;

    while (true) {
      switch (toUpdate) {
        case (?((key, #branch branch), tail)) {
          switch (updateBranchWithDB(branch, key, replacementNode, db)) {
            case (#ok(node)) { replacementNode := node };
            case (#err(hash)) { return #err(hash) };
          };
          hash := nodeHash(replacementNode);
          db.put(hash, replacementNode);
          replacementNode := #hash hash;
          toUpdate := tail;
        };
        case (?((key, #extension ext), tail)) {
          switch (updateExtensionWithDB(ext, replacementNode, db)) {
            case (#ok(node)) { replacementNode := node };
            case (#err(hash)) { return #err(hash) };
          };
          hash := nodeHash(replacementNode);
          db.put(hash, replacementNode);
          replacementNode := #hash hash;
          toUpdate := tail;
        };
        case (?((k, n), _)) {
          Debug.trap("Trie.putWithDB: expected findPath.stack to only contain #branch or #extension but got " # nodeToText(n) # " at " # Key.toText(k));
        };
        case (null) {
          return #ok(replacementNode);
        };
      };
    };

    Debug.trap("unreachable (end of Trie.putWithDB)");
  };
};
