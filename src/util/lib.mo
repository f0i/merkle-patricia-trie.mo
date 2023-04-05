import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Array "mo:base/Array";

/// Helper functions
module {
    type Result<T, E> = Result.Result<T, E>;

    /// Get the success value from a Result
    /// Traps if result is #err
    public func unwrap<T, E>(input : Result<T, E>) : T {
        switch (input) {
            case (#ok(value)) { value };
            case (#err(error)) {
                Debug.trap("unwrap expects input to be #ok(value)");
            };
        };
    };

    /// Drop `n` elements from an array of bytes
    /// Returns an empty array if n is greater than the size of `data`
    public func dropBytes(data : [Nat8], n : Nat) : [Nat8] {
        if (n == 0) return data;
        let size = data.size();
        if (size < n) return [];
        Array.tabulate<Nat8>(size - n, func i = data[i + n]);
    };

    /// Take `n` bytes from an array of bytes
    /// Returns `data` if n is greater than the size of `data`
    public func takeBytes(data : [Nat8], n : Nat) : [Nat8] {
        if (n == 0) return [];
        let size = data.size();
        if (n >= size) return data;
        Array.tabulate<Nat8>(n, func i = data[i]);
    };

};
