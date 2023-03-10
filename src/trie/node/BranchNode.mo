import Buffer "../../util/Buffer";
import Array "mo:base/Array";
import Types "../../Types";

module {
    type EmbeddedNode = Types.EmbeddedNode;

    public type BranchNode = {
        branches : [var ?EmbeddedNode];
        value : ?Buffer.Buffer;
    };

    public func empty() : BranchNode {
        let branches = Array.init<?EmbeddedNode>(16, null);
        return {
            branches;
            value = null;
        };
    };
};
