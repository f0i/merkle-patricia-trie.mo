import Buffer "mo:base/Buffer";
import RLP "mo:rlp";
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

    public func encodeArray(array : [Nat8]) : [Nat8] {
        let buffer = Buffer.fromArray<Nat8>(array);
        let rlpResult = RLP.encode(#Uint8Array buffer);
        let rlpBuffer = Util.unwrap(rlpResult);
        return Buffer.toArray<Nat8>(rlpBuffer);
    };

    public func encodeArrays(arrays : [[Nat8]]) : [Nat8] {
        let buffer = Buffer.Buffer<RLPType.Input>(arrays.size());
        for (i in Iter.range(0, arrays.size() - 1)) {
            let array = arrays[i];
            buffer.add(#Uint8Array(Buffer.fromArray<Nat8>(arrays[i])));
        };

        let rplResult = RLP.encode(#List buffer);
        let rlpBuffer = Util.unwrap(rplResult);
        return Buffer.toArray(rlpBuffer);
    };

    public func encodeEach(arrays : [[Nat8]]) : [[Nat8]] {
        Array.map<[Nat8], [Nat8]>(arrays, encodeArray);
    };

    public func encodeOuter(arrays : [[Nat8]]) : [Nat8] {
        let output = encodeLength(arrays.size(), 192);
        for (val in arrays.vals()) {
            output.append(Buffer.fromArray(val));
        };
        return Buffer.toArray(output);
    };

    private func encodeLength(len : Nat, offset : Nat) : Buffer {
        if (len < 56) {
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

};
