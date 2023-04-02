import O "mo:base/Option";
import Array "mo:base/Array";

module {
    public func last<T>(arr : [T]) : ?T {
        switch (arr.size()) {
            case (0) { return null };
            case (n) { return ?arr[n -1] };
        };
    };
};
