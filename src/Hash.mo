import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import BaseHash "mo:base/Hash";
import Hex "util/Hex";

module {
    public type Hash = Blob;

    public let empty : Hash = "\80";

    public func fromHex(hex : Text) : ?Hash {
        switch (Hex.toArray(hex)) {
            case (#ok(value)) { ?Blob.fromArray(value) };
            case (#err(error)) { null };
        };
    };

    /// compare a sequence of bytes
    public func equal(self : Hash, other : Hash) : Bool = self == other;

    /// generate a 32-bit hash
    public func hash(self : Hash) : BaseHash.Hash {
        Blob.hash(self);
    };

    public func toArray(value : Hash) : [Nat8] {
        return Blob.toArray(value);
    };

    public func toHex(value : Hash) : Text {
        Hex.toText(toArray(value));
    };
};
