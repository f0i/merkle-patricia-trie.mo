# Merkle Patricia Trie

Implementation of a Merkle Patricia Trie in Motoko.

## Install

### MOPS

A easy way to use this library is by using the package manager MOPS.
After [installing mops](https://mops.one/docs/install), you can install [merkle-patricia-trie](https://mops.one/merkle-patricia-trie) by running the following command:

```bash
mops add merkle-patricia-trie
```

### Vessel

An alternative package manager is [Vessel](https://github.com/dfinity/vessel).

Add the repository to `package-set.dhall`:

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

## Usage

Here is a basic example of how to use this library:

```mo
import Trie "mo:merkle-patricia-trie/Trie";
import Key "mo:merkle-patricia-trie/Key";
import Value "mo:merkle-patricia-trie/Value";
import Proof "mo:merkle-patricia-trie/Proof";

// Create an empty trie and add a key/value paiir
var trie = Trie.init();
trie := Trie.put(trie, Key.fromText("one"), Value.fromText("value1"));

// Get value
let value = Trie.get(trie, Key.fromText("one"));
assert value == ?Value.fromText("value1");

// Get the root hash of the trie
let hash = Trie.rootHash(trie);

// Create a proof
let proof = Proof.create(trie, Key.fromText("one"));

// Verify the proof against the root hash
let proofResult = Proof.verify(hash, Key.fromText("one"), proof);

// Print proof result
switch(proofResult) {
  case (#included value) {Debug.print("Proof was valid and returned value " # Value.toHex(value))};
  case (#excluded) {Debug.print("Proof was valid and key is not included in trie")};
  case (#invalidProof) {Debug.print("Proof was invalid. Can not make statement about the key")};
};
```

For all available function see the docs:

- [Trie](docs/Trie.adoc)
- [Proof](docs/Proof.adoc)
- [Key](docs/Key.adoc)
- [Value](docs/Value.adoc)
- [Hash](docs/Hash.adoc)


### Usage with a separate DB

For each function there is an alternative version with the postfix `WithDb`. This allows you to store paris of Hash/Node in a separate key value store (e.g. [MotokoStableBTree](https://github.com/sardariuss/MotokoStableBTree)).

**Usage of `put` and `putWithDb` should not be mixed and can cause a trap!**

## Performance

Using the `put`function to build the trie will use less memory than than using `putWithDb` for the following reasons:

- intermediate nodes added with `put` will be detached and can be deleted by the garbage collector whereas `putWithDb` keeps them in the database.
- Additional overhead for the data structure used by the database

Performance is mostly limited by the hashing function used (Sha3/Keccak). Using the `put` function will calculate the hash of each Node on demand when `rootHash` is calculated. Using `putWithDb` will calculate each node hash immediately even for intermediate nodes which are not used in the final trie.

## References

- Specification on [ethereum.org](https://ethereum.org/en/developers/docs/data-structures-and-encoding/patricia-merkle-trie/)
- TypeScript implementation in [github.com/ethereumjs/.../trie](https://github.com/ethereumjs/ethereumjs-monorepo/tree/master/packages/trie)
- Medium post with  [Ethereum Merkle Patricia Trie Explained](https://medium.com/@chiqing/merkle-patricia-trie-explained-ae3ac6a7e123)

## Testing

All test cases can be executed using the `test.sh` script.

```bash
./test.sh
```

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