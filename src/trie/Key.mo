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
import Util "../util";
import Option "mo:base/Option";

module {
    type Result<T, E> = Result.Result<T, E>;
    type Nibble = Nibble.Nibble;

    public type Key = [Nibble];

    public func fromText(text : Text) : Key {
        let encoded = Text.encodeUtf8(text);
        let bytes = Blob.toArray(encoded);
        Nibble.fromArray(bytes);
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
        return Util.dropBytes(key, n);
    };

    public func take(key : Key, n : Nat) : Key {
        Util.takeBytes(key, n);
    };

    public func join(a : Key, b : Key) : Key {
        let sizeA = a.size();
        let sizeB = b.size();
        Array.tabulate(sizeA + sizeB, func(x : Nat) : Nibble = if (x < sizeA) a[x] else b[x - sizeA]);
    };

    public func append(a : Key, b : Nibble) : Key {
        Array.tabulate(a.size() + 1, func(x : Nat) : Nibble = if (x < a.size()) a[x] else b);
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

    public func compactDecode(encoded : Blob) : {
        key : Key;
        terminating : Bool;
    } {
        let size : Nat = encoded.size();
        if (size < 1) return { key = []; terminating = true };

        let iter = encoded.vals();
        let (prefix, first) = Nibble.splitByte(Option.get<Nat8>(iter.next(), 0));
        let even = (prefix == 0) or (prefix == 2);
        let terminating = prefix >= 2;

        let keySize : Nat = size * 2 - (if (even) 2 else 1);

        var cache = if (even) null else ?first;
        let key = Array.tabulate<Nibble>(
            keySize,
            func(x) : Nibble {
                switch (cache) {
                    case (?nibble) {
                        cache := null;
                        return nibble;
                    };
                    case (null) {
                        let (a, b) = Nibble.splitByte(Option.get<Nat8>(iter.next(), 0));
                        cache := ?b;
                        return a;
                    };
                };
            },
        );

        return { key; terminating };
    };
};
