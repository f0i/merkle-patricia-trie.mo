import Iter "mo:base/Iter";
import Array "mo:base/Array";

/// Helper functions for Iter
module {

    /// Access elements of an iterator two at a time
    /// If `iter` contains an odd number of elements, the last one is discarded
    public func pairs<T>(iter : Iter.Iter<T>) : Iter.Iter<(T, T)> {

        func next() : ?(T, T) {
            switch (iter.next(), iter.next()) {
                case (?a, ?b) { return ?(a, b) };
                case (_, _) { return null };
            };

        };

        return { next };
    };
};
