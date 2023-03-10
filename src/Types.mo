import Nat8 "mo:base/Nat8";
import Buffer "util/Buffer";
import TrieMap "mo:base/TrieMap";
import Blob "mo:base/Blob";
import Bool "mo:base/Bool";

module {

    type Buffer = [Nat8];
    type Map<A, B> = TrieMap.TrieMap<A, B>;

    type TrieNode = { #BranchNode; #ExtensionNode; #LeafNode };

    type Nibbles = [Nat8];

    public type EmbeddedNode = { #Buffer; #BufferArr };

    type Proof = { #BufferArr };

    type BatchDBOp = {
        #put : { key : Buffer; value : Buffer };
        #del : { key : Buffer };
    };

    type Checkpoint = {
        // We cannot use a Buffer => Buffer map directly. If you create two Buffers with the same internal value,
        // then when setting a value on the Map, it actually creates two indices.
        keyValueMap : Map<Text, ?Buffer>;
        root : Buffer;
    };

    type TrieOptsWithDefaults = {
        useKeyHashing : Bool;
        //useKeyHashingFunction : HashKeysFunction;
        useRootPersistence : Bool;
        useNodePruning : Bool;
    };

    let ROOT_DB_KEY : Buffer = [0x5f, 0x5f, 0x72, 0x6f, 0x6f, 0x74, 0x5f, 0x5f]; // return value of `Buffer.fromText("__root__")`

};
