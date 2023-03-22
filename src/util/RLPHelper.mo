import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Util ".";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";

import RLP "rlp/encode";
import RLPDecode "mo:rlp/rlp/decode";
import RLPType "mo:rlp/types";

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
            return [0x80]; // RLP encoded empty array
        };
        let len = Array.foldLeft<[Nat8], Nat>(arrays, 0, func(sum, a) = sum + a.size());
        let lengthPrefix = RLP.encodeLength(len, 192); // RLP prefix for lists
        let output = Util.unwrap(lengthPrefix);
        for (val in arrays.vals()) {
            output.append(Buffer.fromArray(val));
        };
        return Buffer.toArray(output);
    };

    // Decode one level of an RLP encoded array
    public func decode(input : [Nat8]) : { #ok : [[Nat8]]; #err : Text } {
        let info = getPrefixInfo(input);
        switch (info) {
            case (?{ rlpType = #shortString; data = 0; prefix = 1 }) {
                if (input.size() != 1) {
                    return #err("RLP error: too many bytes");
                };
                return #ok([]);
            };
            case (?{ rlpType = #shortList; data; prefix }) {
                let remaining = Util.dropBytes(input, prefix);
                return splitMultiple(remaining);
            };
            case (?{ rlpType = #longList; data; prefix }) {
                let remaining = Util.dropBytes(input, prefix);
                return splitMultiple(remaining);
            };
            case (_) { return #err("unexpected RLP type") };
        };
    };

    /// Split an rlp byte sequence into multiple, each representing an rlp encoded string
    /// This function does not decode them; it just looks at the length of each segment
    func splitMultiple(input : [Nat8]) : { #ok : [[Nat8]]; #err : Text } {
        let info = getPrefixInfo(input);
        switch (info) {
            case (?{ prefix; data }) {
                let size = prefix + data;
                assert size > 0; // getPrefix info must never return 0 for both prefix and data

                //Debug.print("slpitMultiple: decode " # Nat.toText(size) # " of " # Nat.toText(input.size()) # " bytes");
                if (input.size() < size) {
                    return #err("RLP error: too few bytes");
                };

                let first = Util.takeBytes(input, prefix + data);
                let tail = Util.dropBytes(input, prefix + data);

                if (tail == []) return #ok([first]);

                switch (splitMultiple(tail)) {
                    case (#err(msg)) { return #err(msg) };
                    case (#ok(others)) {
                        return #ok(
                            Array.tabulate<[Nat8]>(
                                others.size() + 1,
                                func(i) : [Nat8] {
                                    if (i == 0) { first } else { others[i -1] };
                                },
                            )
                        );
                    };
                };

                #err("TODO: implement splitMultiple");
            };
            case (null) {
                return #err("RLP error: couldn't determine type or length");
            };
        };
    };

    private func extractNat8Arrays(data : Buffer.Buffer<RLPType.Decoded>) : {
        #ok : [[Nat8]];
        #err : Text;
    } {
        let size = data.size();
        var out = Array.init<[Nat8]>(size, []);
        for (i in Iter.range(0, size - 1)) {
            switch (data.get(i)) {
                case (#Uint8Array(value)) {};
                case (#Nested(_)) { return #err("unexpected RLP nesting") };
            };
        };

        return #ok([]);
    };

    type RlpDataType = {
        #singleByte;
        #shortString;
        #longString;
        #shortList;
        #longList;
    };

    public func getType(encodedData : [Nat8]) : RlpDataType {
        assert encodedData != [];

        let prefix = encodedData[0];
        if (prefix < 0x80) {
            return #singleByte;
        } else if (prefix < 0xb8) {
            return #shortString;
        } else if (prefix < 0xc0) {
            return #longString;
        } else if (prefix < 0xf8) {
            return #shortList;
        } else {
            return #longList;
        };
    };

    public func getPrefixInfo(encodedData : [Nat8]) : ?{
        rlpType : RlpDataType;
        prefix : Nat;
        data : Nat;
    } {
        if (encodedData == []) return null;

        let prefix = Nat8.toNat(encodedData[0]);
        let rlpType = getType(encodedData);

        switch (rlpType) {
            case (#singleByte) { return ?{ rlpType; prefix = 0; data = 1 } };
            case (#shortString) {
                return ?{ rlpType; prefix = 1; data = prefix - 0x80 };
            };
            case (#longString) {
                let lengthLength = prefix - 0xb7;
                var length = 0;
                for (i in Iter.range(1, lengthLength)) {
                    length *= 0x100;
                    length += Nat8.toNat(encodedData[i]);
                };
                return ?{ rlpType; prefix = 1 + lengthLength; data = length };
            };
            case (#shortList) {
                return ?{ rlpType; prefix = 1; data = prefix - 0xc0 };
            };
            case (#longList) {
                let lengthLength = prefix - 0xf7;
                var length = 0;
                for (i in Iter.range(1, lengthLength)) {
                    length *= 0x100;
                    length += Nat8.toNat(encodedData[i]);
                };
                return ?{ rlpType; prefix = 1 + lengthLength; data = length };
            };
        };
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