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
...
let additions = [
  { name = "merkle-patricia-trie"
  , version = "master"
  , repo = "https://github.com/f0i/merkle-patricia-trie.mo"
  , dependencies = [ "base", "rlp", "sha3" ],
  },
  { name = "rlp"
  , version = "master"
  , repo = "https://github.com/relaxed04/rlp-motoko"
  , dependencies = [] : List Text
  },
  { name = "sha3"
  , version = "master"
  , repo = "https://github.com/hanbu97/motoko-sha3"
  , dependencies = [] : List Text
  }
] : List Package
...
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
import Hash "mo:merkle-patricia-trie/Hash";
import Proof "mo:merkle-patricia-trie/Proof";
import Debug "mo:base/Debug";

// Create an empty trie and add a key/value pair
var trie = Trie.init();
trie := Trie.put(trie, Key.fromText("one"), Value.fromText("value1"));

// Get value
let value = Trie.get(trie, Key.fromText("one"));
assert value == ?Value.fromText("value1");

// Get the root hash of the trie
let hash = Trie.hash(trie);

// Create a proof
let proof = Proof.create(trie, Key.fromText("one"));

// Verify the proof against the root hash
let proofResult = Proof.verify(hash, Key.fromText("one"), proof);

// Print proof result
switch (proofResult) {
    case (#included value) {
        Debug.print("Proof was valid and returned value " # Value.toHex(value));
    };
    case (#excluded) {
        Debug.print("Proof was valid and key is not included in trie");
    };
    case (#invalidProof) {
        Debug.print("Proof was invalid. Can not make statement about the key");
    };
};
```

For all available function see the docs:

- [Trie](docs/Trie.adoc)
- [Proof](docs/Proof.adoc)
- [Key](docs/Key.adoc)
- [Value](docs/Value.adoc)
- [Hash](docs/Hash.adoc)


### Usage with a separate DB

There is a second implementation `TrieWithDb` which stores paris of Hash/Node in a separate key value store (e.g. [MotokoStableBTree](https://github.com/sardariuss/MotokoStableBTree)).

To use it, replace the import of `Trie` with `TrieWithDB` and use `Proof.createWithDB` to create proofs:

```mo
import Trie "mo:merkle-patricia-trie/TrieWithDB";
import Key "mo:merkle-patricia-trie/Key";
import Value "mo:merkle-patricia-trie/Value";
import Hash "mo:merkle-patricia-trie/Hash";
import Proof "mo:merkle-patricia-trie/Proof";
import TrieMap "mo:base/TrieMap";
import Debug "mo:base/Debug";

// Create an empty trie and add a key/value pair
var trie = Trie.init();
let db = TrieMap.TrieMap<Hash.Hash, Trie.Node>(Hash.equal, Hash.hash);

switch (Trie.put(trie, Key.fromText("one"), Value.fromText("value1"), db)) {
  case (#ok newTrie) { trie := newTrie };
  case (#err hash) { Debug.trap("missing hash: " # Hash.toHex(hash)) };
};

// Get value
let value = Trie.get(trie, Key.fromText("one"), db);
assert value == #ok(?Value.fromText("value1"));

// Get the root hash of the trie
let hash = Trie.hash(trie);

// Create a proof
let proof = switch (Proof.createWithDB(trie, Key.fromText("one"), db)) {
  case (#ok(proof)) { proof };
  case (#err(hash)) { Debug.trap("missing hash: " # Hash.toHex(hash)) };
};

// Verify the proof against the root hash
let proofResult = Proof.verify(hash, Key.fromText("one"), proof);

// Print proof result
switch (proofResult) {
  case (#included value) {
    Debug.print("Proof was valid and returned value " # Value.toHex(value));
  };
  case (#excluded) {
    Debug.print("Proof was valid and key is not included in trie");
  };
  case (#invalidProof) {
    Debug.print("Proof was invalid. Can not make statement about the key");
  };
};

```

**Usage of `Trie` and `TrieWithDb` should not be mixed and can cause a trap!**

## Performance

Using the `put`function to build the trie will use less memory than than using `putWithDb` for the following reasons:

- intermediate nodes added with `put` will be detached and can be deleted by the garbage collector whereas `putWithDb` keeps them in the database.
- Additional overhead for the data structure used by the database

Performance is mostly limited by the hashing function used (Sha3/Keccak). Using the `put` function will calculate the hash of each Node on demand when `rootHash` is calculated. Using `putWithDb` will calculate each node hash immediately even for intermediate nodes which are not used in the final trie.

## Testing

All test cases can be executed using the `test.sh` script.

```bash
./test.sh
```

## References

- Specification on [ethereum.org](https://ethereum.org/en/developers/docs/data-structures-and-encoding/patricia-merkle-trie/)
- TypeScript implementation in [github.com/ethereumjs/.../trie](https://github.com/ethereumjs/ethereumjs-monorepo/tree/master/packages/trie)
- Medium post with  [Ethereum Merkle Patricia Trie Explained](https://medium.com/@chiqing/merkle-patricia-trie-explained-ae3ac6a7e123)
