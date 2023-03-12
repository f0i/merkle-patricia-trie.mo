import Buffer "../util/Buffer";
import SHA3 "mo:sha3";
import RLP "mo:rlp";
import BaseBuffer "mo:base/Buffer";
import Result "mo:base/Result";
import Nibble "../util/Nibble";
import Nat8 "mo:base/Nat8";

module {
    public type Key = Buffer.Buffer;
    type Buffer = Buffer.Buffer;
    type Result<T, E> = Result.Result<T, E>;

    /// Convert a buffer into a key by applying RPL and Keccak
    public func fromBuffer(buffer : Buffer) : Result<Key, Text> {
        let bbuffer = BaseBuffer.fromArray<Nat8>(buffer);
        let rpl_encoded = switch (RLP.encode(#Uint8Array bbuffer)) {
            case (#ok(value)) { BaseBuffer.toArray(value) };
            case (#err(error)) { return #err("RPL error:" # error) };
        };

        var sha = SHA3.Keccak(256);
        sha.update(rpl_encoded);
        return #ok(sha.finalize());
    };

    /// get the first nibble of the key and turn it into a Nat for using as index
    public func toIndex(key : Key) : Nat {
        Nat8.toNat(key[0]);
    };
};
