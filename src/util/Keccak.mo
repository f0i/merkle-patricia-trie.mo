import SHA3 "mo:sha3";
import Buffer "Buffer";

module {
    type Buffer = [Nat8];
    type Hash = [Nat8];

    public func keccak(data : Buffer) : Hash {

        var sha = SHA3.Keccak(256);
        sha.update(data);
        return sha.finalize();
    };
};
