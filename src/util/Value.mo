import Text "mo:base/Text";
import Blob "mo:base/Blob";

module {
    type Value = [Nat8];

    public func fromText(text : Text) : Value {
        let encoded = Text.encodeUtf8(text);
        Blob.toArray(encoded);
    };
};
