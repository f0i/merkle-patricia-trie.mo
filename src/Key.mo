import SHA3 "mo:sha3";
import RLP "mo:rlp";
import BaseBuffer "mo:base/Buffer";
import Result "mo:base/Result";
import Nibble "util/Nibble";
import Nat8 "mo:base/Nat8";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Util "util";
import Option "mo:base/Option";
import Hex "util/Hex";

/// Data structure for Key
module {
    type Result<T, E> = Result.Result<T, E>;
    type Nibble = Nibble.Nibble;

    /// Key data
    public type Key = [Nibble];

    /// Convert text into a Key
    public func fromText(text : Text) : Key {
        let encoded = Text.encodeUtf8(text);
        let bytes = Blob.toArray(encoded);
        Nibble.fromArray(bytes);
    };

    /// Convert hex Text into a Key
    public func fromHex(hex : Text) : ?Key {
        let data = Hex.toArray(hex);
        switch (data) {
            case (#ok bytes) { ?Nibble.fromArray(bytes) };
            case (#err _) { return null };
        };
    };

    /// Checks if the input has a hex prefix and convert it to a Key
    /// If it has a hex prefix but contains non-hex digits, null is returned
    public func fromHexOrText(input : Text) : ?Key {
        switch (Text.stripStart(input, #text "0x")) {
            case (?hex) { fromHex(hex) };
            case (null) { ?fromText(input) };
        };
    };

    /// Convert an array of bytes into a Key
    public func fromKeyBytes(bytes : [Nat8]) : Key {
        return Nibble.fromArray(bytes);
    };

    /// Get the number of matching nibbles
    public func matchingLength(a : Key, b : Key) : Nat {
        return Nibble.matchingNibbleLength(a, b);
    };

    /// Remove leading nibbles from a Key
    /// If there are less than `n` nibbles in the `key`, an empty Key is returned
    public func drop(key : Key, n : Nat) : Key {
        return Util.dropBytes(key, n);
    };

    /// Create a new key from the first `n` nibbles of `key`
    /// If `n` is larger than the number of nibbles in `key`, `key` is returned
    public func take(key : Key, n : Nat) : Key {
        Util.takeBytes(key, n);
    };

    /// Combine two keys
    public func join(a : Key, b : Key) : Key {
        let sizeA = a.size();
        let sizeB = b.size();
        Array.tabulate(sizeA + sizeB, func(x : Nat) : Nibble = if (x < sizeA) a[x] else b[x - sizeA]);
    };

    /// Create a new key by extending `a` by one nibble `b`
    public func append(a : Key, b : Nibble) : Key {
        Array.tabulate(a.size() + 1, func(x : Nat) : Nibble = if (x < a.size()) a[x] else b);
    };

    public func addPrefix(a : Nibble, key : Key) : Key {
        Array.tabulate(key.size() + 1, func(x : Nat) : Nibble = if (x == 0) a else key[x - 1]);
    };

    /// Generate a human readable Text representation of a Key
    public func toText(key : Key) : Text {
        let values : [Text] = Array.map<Nibble, Text>(key, Nat8.toText);
        let keyText = Text.join(",", values.vals());

        "key[" # keyText # "]";
    };

    /// Get the first nibble of the key and turn it into a Nat for using as index
    public func toIndex(key : Key) : Nat {
        Nat8.toNat(key[0]);
    };

    /// Encode a Key into a compact encoded array of bytes
    /// see <https://ethereum.org/en/developers/docs/data-structures-and-encoding/patricia-merkle-trie/#specification>
    public func compactEncode(key : Key, terminating : Bool) : [Nat8] {
        let even = key.size() % 2 == 0;
        let size = (key.size() / 2) + 1;
        var arr = Array.init<Nat8>(size, 0);

        if (even) {
            arr[0] := 0x00;
            for (i in Iter.range(0, size - 2)) {
                arr[i + 1] := (key[i * 2] * 16) + key[i * 2 +1];
            };
        } else {
            arr[0] := 0x10 + key[0];
            for (i in Iter.range(0, size - 2)) {
                arr[i + 1] := (key[i * 2 + 1] * 16) + key[i * 2 + 2];
            };
        };

        if (terminating) {
            arr[0] += 0x20;
        };

        return Array.freeze<Nat8>(arr);
    };

    /// Decode a compact encoded array of bytes
    /// see <https://ethereum.org/en/developers/docs/data-structures-and-encoding/patricia-merkle-trie/#specification>
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
