import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Hex "util/Hex";

/// A Value to store inside a Trie
module {
    /// Value type
    public type Value = Blob;

    /// An empty Value (no data)
    public let empty : Value = "";

    /// Convert Text into a Value
    public func fromText(text : Text) : Value {
        Text.encodeUtf8(text);
    };

    /// Convert a hex Text into a Value
    public func fromHex(hex : Text) : ?Value {
        switch (Hex.toArray(hex)) {
            case (#ok(value)) { ?Blob.fromArray(value) };
            case (#err(error)) { null };
        };
    };

    /// Convert an array of bytes into a Value
    public func fromArray(data : [Nat8]) : Value {
        return Blob.fromArray(data);
    };

    /// Convert a Value into an array of bytes
    public func toArray(value : Value) : [Nat8] {
        return Blob.toArray(value);
    };

    /// Convert a Value into hex Text
    public func toHex(value : Value) : Text {
        Hex.toText(toArray(value));
    };
};
