import SHA3 "mo:sha3";
import Blob "mo:base/Blob";

module {
    type Buffer = [Nat8];
    type Hash = Blob;

    public func keccak(data : Buffer) : Hash {

        var sha = SHA3.Keccak(256);
        sha.update(data);
        return Blob.fromArray(sha.finalize());
    };
};
