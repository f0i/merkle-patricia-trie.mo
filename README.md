# Merkle Patricia Trie

Implementation of a Merkle Patricia Trie in Motoko.


## References

- Specification on [ethereum.org](https://ethereum.org/en/developers/docs/data-structures-and-encoding/patricia-merkle-trie/)
- TypeScript implementation in [github.com/ethereumjs/.../trie](https://github.com/ethereumjs/ethereumjs-monorepo/tree/master/packages/trie)

## Testing

All test cases can be executed using the `test.sh` script.

```bash
./test.sh
```

The test cases are defined in `/test/**.spec.mo`.

### REPL

For interactive debugging, the REPL mode can be used:

```bash
rlwrap $(vessel bin)/moc $(vessel sources) -i
```

Then you can import everything and start testing:

```motoko
import Nibble "src/util/Nibble";
import Trie "src/MerklePatriciaTrie";
import Key "src/trie/Key";
import Buffer "src/util/Buffer";
import Debug "mo:base/Debug";

type Trie = Trie.Trie;
type Buffer = Buffer.Buffer;
type Key = Key.Key;

func testKey() : Key {
    switch (Key.fromBuffer([0])) {
        case (#ok key) { key };
        case (_) { Debug.trap("Failed to get key") };
    };
};
```