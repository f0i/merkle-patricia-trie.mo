import Buffer "../util/Buffer";
import SHA3 "mo:sha3";
import RLP "mo:rlp";
import BaseBuffer "mo:base/Buffer";
import Result "mo:base/Result";
import Nibble "../util/Nibble";
import Nat8 "mo:base/Nat8";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";

module {
    type Buffer = Buffer.Buffer;
    type Result<T, E> = Result.Result<T, E>;
    type Nibble = Nibble.Nibble;

    public type Key = [Nibble];

    public func fromText(text : Text) : Key {
        let encoded = Text.encodeUtf8(text);
        let bytes = Blob.toArray(encoded);
        Nibble.fromArray(bytes);
    };

    /// Convert a buffer into a key by applying RPL and Keccak
    public func fromBuffer(buffer : Buffer) : Result<Key, Text> {
        let bBuffer = BaseBuffer.fromArray<Nat8>(buffer);
        let rpl_encoded = switch (RLP.encode(#Uint8Array bBuffer)) {
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

    public func compactEncode(nibbles : [Nibble], terminating : Bool) : [Nat8] {
        let even = nibbles.size() % 2 == 0;
        let size = (nibbles.size() / 2) + 1;
        var arr = Array.init<Nat8>(size, 0);

        if (even) {
            arr[0] := 0x00;
            for (i in Iter.range(0, size - 2)) {
                arr[i + 1] := (nibbles[i * 2] * 16) + nibbles[i * 2 +1];
            };
        } else {
            arr[0] := 0x10 + nibbles[0];
            for (i in Iter.range(0, size - 2)) {
                arr[i + 1] := (nibbles[i * 2 + 1] * 16) + nibbles[i * 2 + 2];
            };
        };

        if (terminating) {
            arr[0] += 0x20;
        };

        return Array.freeze<Nat8>(arr);
    };
};
