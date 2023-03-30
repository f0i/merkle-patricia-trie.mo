# Merkle Patricia Trie

Implementation of a Merkle Patricia Trie in Motoko.

## Install

### Vessel

Add the repository to the package set:

```dhall
let additions = [
  { name = "merkle-patricia-trie"
  , version = "master"
  , repo = "https://github.com/f0i/merkle-patricia-trie.mo"
  , dependencies = [] : List Text
  },
  ...
] : List Package
```

and to the dependencies in `vessel.dhall`:

```dhall
{
  dependencies = [ "base", "merkle-patricia-trie" ],
  compiler = Some "0.7.4"
}
```

### MOPS

```bash
mops add https://github.com/f0i/merkle-patricia-trie.mo
```

## Usage

```mo
import Trie "mo:merkle-patricia-trie";

var trie = Trie.init();
trie := Trie.put(trie, Key.fromText("one"), [0x12, 0x34, 0x56]);

```

## References

- Specification on [ethereum.org](https://ethereum.org/en/developers/docs/data-structures-and-encoding/patricia-merkle-trie/)
- TypeScript implementation in [github.com/ethereumjs/.../trie](https://github.com/ethereumjs/ethereumjs-monorepo/tree/master/packages/trie)
- Medium post with  [Ethereum Merkle Patricia Trie Explained](https://medium.com/@chiqing/merkle-patricia-trie-explained-ae3ac6a7e123)

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

var trie = Trie.init();
let key1 = Key.fromKeyBytes([0x12, 0x34]);
let key2 = Key.fromKeyBytes([0x22, 0x34]);
trie := Trie.put(trie, key1, {});
trie := Trie.put(trie, key2, {});

Debug.print(Trie.toText(trie))
```