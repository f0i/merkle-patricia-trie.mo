import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
module {
    type Result<T, E> = Result.Result<T, E>;
    public func unwrap<T, E>(input : Result<T, E>) : T {
        switch (input) {
            case (#ok(value)) { value };
            case (#err(error)) {
                Debug.trap("unwrap expects input to be #ok(value)");
            };
        };
    };

    public func dropBytes(data : [Nat8], n : Nat) : [Nat8] {
        if (n == 0) return data;
        let size = data.size();
        if (size < n) return [];
        Array.tabulate<Nat8>(size - n, func i = data[i + n]);
    };

    public func takeBytes(data : [Nat8], n : Nat) : [Nat8] {
        if (n == 0) return [];
        let size = data.size();
        if (n >= size) return data;
        Array.tabulate<Nat8>(n, func i = data[i]);
    };

};
