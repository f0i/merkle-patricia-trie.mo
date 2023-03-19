import Result "mo:base/Result";
import Debug "mo:base/Debug";
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

};
