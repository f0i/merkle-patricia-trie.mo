import Debug "mo:base/Debug";

/// Test helper
module Test {
    /// Indicate a test section
    /// It is recommended to be used in combination with a do-block
    public func section(title : Text) = Debug.print("\n#" # " " # title # "\n");

    public func test(name : Text) = Debug.print("- " # name);
};
