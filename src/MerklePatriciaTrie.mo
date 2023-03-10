import Arr "ArrayExtra";
import Array "mo:base/Array";
import Buffer "util/Buffer";
import Debug "mo:base/Debug";
import List "mo:base/List";
import Nibble "util/Nibble";
import BranchNode "trie/node/BranchNode";

module {
  public type MerklePatriciaTrie = Node;
  public type Trie = Node;
  type Buffer = Buffer.Buffer;
  type Nibble = Nibble.Nibble;

  public type Node = {
    #nul;
    #branch : Branch;
    #leaf : (EncodedPath, Value);
    #extension : (EncodedPath, Key);
  };

  type Branch = BranchNode.BranchNode;

  type EncodedPath = {};

  type Path = {};

  type Value = {};

  type Key = {};

  public func init(root : Buffer) : Trie {
    #nul;
  };

  public func put(trie : Trie, key : Buffer, value : Buffer) : () {
    Debug.trap("implement");
  };

  public func get(trie : Trie, key : Buffer) : ?Buffer {
    let path = findPath(trie, key);
    Debug.print("TODO: implement get");
    return null;
  };

  public func del(trie : Trie, key : Buffer) : ?Buffer {
    Debug.trap("implement");
  };

  public func findPath(trie : Trie, key : Buffer) : Path {
    Debug.print("implement findPath");
    let stack = List.nil<Node>();
    let targetKey = Nibble.fromArray(key);

    func step(node : Node, nibbles : [Nibble]) {
      switch (node) {
        case (#nul) { return };
        case (#leaf leaf) { return /*TODO*/ };
        case (#branch branch) {
          return;
        };
        case (#extension ext) {
          return;
        };
      };
    };

    return {};
  };

  func lookupNode(trie : Trie, node : Buffer) {

  };

  func allChildren(node : Node) : [Node] {
    Debug.trap("implement");
  };
};
