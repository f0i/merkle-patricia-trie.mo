import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Hex "util/Hex";

module {
    public type Value = Blob;

    public let empty : Value = "";

    public func fromText(text : Text) : Value {
        Text.encodeUtf8(text);
    };

    public func fromHex(hex : Text) : ?Value {
        switch (Hex.toArray(hex)) {
            case (#ok(value)) { ?Blob.fromArray(value) };
            case (#err(error)) { null };
        };
    };

    public func fromArray(data : [Nat8]) : Value {
        return Blob.fromArray(data);
    };

    public func toArray(value : Value) : [Nat8] {
        return Blob.toArray(value);
    };

    public func toHex(value : Value) : Text {
        Hex.toText(toArray(value));
    };
};
