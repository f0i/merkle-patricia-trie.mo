import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import BaseHash "mo:base/Hash";
import Hex "util/Hex";

/// A Hash to identify a Node by its keccak hash or short RLP encoded value
module {
    /// Hash type
    public type Hash = Blob;

    /// Hash of an empty Node, empty array or null
    public let empty : Hash = "\80";

    /// Convert a hex Text into a Hash
    public func fromHex(hex : Text) : ?Hash {
        switch (Hex.toArray(hex)) {
            case (#ok(value)) { ?Blob.fromArray(value) };
            case (#err(error)) { null };
        };
    };

    /// Compare a Hash to another Hash
    public func equal(self : Hash, other : Hash) : Bool = self == other;

    /// Generate a 32-bit `mo:base/Hash`
    public func hash(self : Hash) : BaseHash.Hash {
        Blob.hash(self);
    };

    /// Convert a Hash into a byte array
    public func toArray(value : Hash) : [Nat8] {
        return Blob.toArray(value);
    };

    /// Convert a Hash into a hex Text
    public func toHex(value : Hash) : Text {
        Hex.toText(toArray(value));
    };
};
