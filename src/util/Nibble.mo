import Nat8 "mo:base/Nat8";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import IterExtra "IterExtra";
import Order "mo:base/Order";

module {
    public type Nibble = Nat8;

    public func fromArray(arr : [Nat8]) : [Nibble] {
        let size = arr.size() * 2;
        var nibbles = Array.init<Nat8>(size, 0);
        for (i in Iter.range(0, arr.size() - 1)) {
            nibbles[i * 2] := arr[i] / 16;
            nibbles[i * 2 + 1] := arr[i] % 16;
        };
        return Array.freeze<Nat8>(nibbles);
    };

    /// Convert an array of nibbles into a array of bytes
    public func toArray(nibbles : [Nibble]) : [Nat8] {
        let size = nibbles.size() / 2;
        var arr = Array.init<Nat8>(size, 0);
        for (i in Iter.range(0, size - 1)) {
            arr[i] := (nibbles[i * 2] * 16) + nibbles[i * 2 +1];
        };
        return Array.freeze<Nat8>(arr);
    };

    /// Split a byte into its nibbles
    public func splitByte(b : Nat8) : (Nibble, Nibble) {
        let high = b / 16;
        let low = b % 16;
        return (high, low);
    };

    /// Merge nibbles into a byte
    /// Assumes that only lower 4 bits are used, larger values can lead to unintended byte values
    public func mergeNibbles(high : Nibble, low : Nibble) : Nat8 {
        return (high * 16) + low;
    };

    /// Merge nibbles into a byte
    /// Only lower 4 bits are used, hihger bits are ignored
    public func mergeNibblesSafe(high : Nibble, low : Nibble) : Nat8 {
        return (high * 16) + (low % 16);
    };

    /// Compare two arrays of nibbles
    public func compare(a : [Nibble], b : [Nibble]) : Order.Order {
        let size = Nat.min(a.size(), b.size());

        for (i in Iter.range(0, size - 1)) {
            if (a[i] < b[i]) {
                return #less;
            };
            if (a[i] > b[i]) {
                return #greater;
            };
        };

        if (a.size() < b.size()) {
            return #less;
        };
        if (b.size() < a.size()) {
            return #greater;
        };

        return #equal;
    };

    public func matchingNibbleLength(a : [Nibble], b : [Nibble]) : Nat {
        let size = Nat.min(a.size(), b.size());

        for (i in Iter.range(0, size - 1)) {
            if (a[i] != b[i]) return i;
        };
        return size;
    };

    public func doKeysMatch(a : [Nibble], b : [Nibble]) : Bool {
        if (a.size() != b.size()) {
            return false;
        } else {
            return matchingNibbleLength(a, b) == a.size();
        };
    };
};
