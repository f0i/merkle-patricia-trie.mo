import Buffer "mo:base/Buffer";
import RLP "mo:rlp/rlp/encode";
import RLPType "mo:rlp/types";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Util ".";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";

module {
    type Buffer = Buffer.Buffer<Nat8>;
    type InternalResult = Result.Result<Buffer, Text>;
    type EncodeResult = Result.Result<[Nat8], Text>;

    public func encodeHash(array : [Nat8]) : [Nat8] {
        if (array.size() == 32) {
            encode(array);
        } else {
            array;
        };
    };
    public func encode(array : [Nat8]) : [Nat8] {
        let buffer = Buffer.fromArray<Nat8>(array);
        let rlpResult = RLP.encode(#Uint8Array buffer);
        let rlpBuffer = Util.unwrap(rlpResult);
        return Buffer.toArray<Nat8>(rlpBuffer);
    };

    public func encodeEach(arrays : [[Nat8]]) : [[Nat8]] {
        Array.map<[Nat8], [Nat8]>(arrays, encode);
    };
    public func encodeEachHash(arrays : [[Nat8]]) : [[Nat8]] {
        Array.map<[Nat8], [Nat8]>(arrays, encodeHash);
    };

    public func encodeOuter(arrays : [[Nat8]]) : [Nat8] {
        if (arrays == []) {
            return [0x80];
        };
        let len = Array.foldLeft<[Nat8], Nat>(arrays, 0, func(sum, a) = sum + a.size());
        let lengthPrefix = RLP.encodeLength(len, 192);
        let output = Util.unwrap(lengthPrefix);
        for (val in arrays.vals()) {
            output.append(Buffer.fromArray(val));
        };
        return Buffer.toArray(output);
    };

    /*

    let OFFSET_LIST_SIZE = 0xc0;

    private func encodeLength(len : Nat, offset : Nat) : Buffer {
        if (len <= 55) {
            return Buffer.fromArray([Nat8.fromNat(len) + Nat8.fromNat(offset)]);
        };

        let lenBytes = toBytes(len, true);
        let firstByte = offset + 55 + lenBytes.size();
        lenBytes.put(0, Nat8.fromNat(firstByte));
        return lenBytes;
    };

    private func toBytes(num : Nat, addLeadingZero : Bool) : Buffer {
        let buffer = Buffer.Buffer<Nat8>(1);
        if (num == 0) {
            buffer.add(0);
        };
        var rest = num;
        while (rest > 0) {
            buffer.add(Nat8.fromNat(rest % 256));
            rest := rest / 256;
        };
        if (addLeadingZero) {
            // add to the end because buffer will be reversed
            buffer.add(0);
        };
        Buffer.reverse(buffer);
        return buffer;
    };
*/
};
