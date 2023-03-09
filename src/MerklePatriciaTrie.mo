import Arr "ArrayExtra";
import Array "mo:base/Array";
import Buffer "util/Buffer";
import Debug "mo:base/Debug";

module {
  public type MerklePatriciaTrie = Node;
  public type Trie = Node;
  type Buffer = Buffer.Buffer;

  public type Node = {
    #nul;
    #branch : Branch;
    #leaf : (EncodedPath, Value);
    #extension : (EncodedPath, Key);
  };

  type Branch = (Node, Node, Node, Node, Node);

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
    Debug.trap("implement");
  };

  public func allChildren(node : Node) : [Node] {
    Debug.trap("implement");
  };
};
