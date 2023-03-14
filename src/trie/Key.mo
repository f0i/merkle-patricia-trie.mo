import Buffer "../util/Buffer";
import SHA3 "mo:sha3";
import RLP "mo:rlp";
import BaseBuffer "mo:base/Buffer";
import Result "mo:base/Result";
import Nibble "../util/Nibble";
import Nat8 "mo:base/Nat8";
import Array "mo:base/Array";
import Text "mo:base/Text";

module {
    type Buffer = Buffer.Buffer;
    type Result<T, E> = Result.Result<T, E>;
    type Nibble = Nibble.Nibble;

    public type Key = [Nibble];

    /// Convert a buffer into a key by applying RPL and Keccak
    public func fromBuffer(buffer : Buffer) : Result<Key, Text> {
        let bbuffer = BaseBuffer.fromArray<Nat8>(buffer);
        let rpl_encoded = switch (RLP.encode(#Uint8Array bbuffer)) {
            case (#ok(value)) { BaseBuffer.toArray(value) };
            case (#err(error)) { return #err("RPL error:" # error) };
        };

        var sha = SHA3.Keccak(256);
        sha.update(rpl_encoded);
        return #ok(Nibble.fromArray(sha.finalize()));
    };

    public func fromKeyBytes(bytes : [Nat8]) : Key {
        return Nibble.fromArray(bytes);
    };

    /// Get the number of matchin nibbles
    public func matchingLength(a : Key, b : Key) : Nat {
        return Nibble.matchingNibbleLength(a, b);
    };

    // TODO: rename to `drop`
    public func slice(key : Key, n : Nat) : Key {
        if (n == 0) return key;
        let size = key.size();
        if (size < n) return [];
        Array.tabulate<Nibble>(size - n, func i = key[i + n]);
    };

    public func take(key : Key, n : Nat) : Key {
        if (n == 0) return [];
        let size = key.size();
        if (n >= size) return key;
        Array.tabulate<Nibble>(n, func i = key[i]);
    };

    public func toText(key : Key) : Text {
        let values : [Text] = Array.map<Nibble, Text>(key, Nat8.toText);
        let keyText = Text.join(",", values.vals());

        "key[" # keyText # "]";
    };

    /// get the first nibble of the key and turn it into a Nat for using as index
    public func toIndex(key : Key) : Nat {
        Nat8.toNat(key[0]);
    };
};
