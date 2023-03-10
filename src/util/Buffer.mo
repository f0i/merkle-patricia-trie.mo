import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Hex "Hex";
//
/// Buffer represents a fixed-length sequence of bytes, similar to node.js Buffer

module {

    public type Buffer = [Nat8];

    // TODO: rename to init, alloc is from js
    public func alloc(size : Nat) : Buffer {
        return Array.freeze(Array.init<Nat8>(size, 0));
    };

    public func fromText(text : Text) : Buffer {
        let encoded = Text.encodeUtf8(text);
        return Blob.toArray(encoded);
    };

    public func fromHex(hex : Text) : ?Buffer {
        switch (Hex.toArray(hex)) {
            case (#ok(value)) { ?Array.freeze(value) };
            case (#err(error)) { null };
        };
    };

};
