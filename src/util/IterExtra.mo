import Iter "mo:base/Iter";
import Array "mo:base/Array";

module {

    /// Access elements of an iterator in pairs
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
