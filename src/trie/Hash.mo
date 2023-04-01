import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Hex "../util/Hex";

module {
    public type Hash = Blob;

    public func fromHex(hex : Text) : ?Hash {
        switch (Hex.toArray(hex)) {
            case (#ok(value)) { ?Blob.fromArray(value) };
            case (#err(error)) { null };
        };
    };

    public func toArray(value : Hash) : [Nat8] {
        return Blob.toArray(value);
    };

    public func toHex(value : Hash) : Text {
        Hex.toText(toArray(value));
    };
};
