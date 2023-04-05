import SHA3 "mo:sha3";
import Blob "mo:base/Blob";
import Hash "../Hash";

module {
    type Hash = Hash.Hash;

    /// Calculate keccak hash of a byte array
    public func keccak(data : [Nat8]) : Hash {

        var sha = SHA3.Keccak(256);
        sha.update(data);
        return Blob.fromArray(sha.finalize());
    };
};
