

# Test results

The following lists all executed test.

The final section shows the test result

## Key

- drop
- take

## compact encode

- [1,2,3,4,5]
- [1,2,3,4,5,6]

## Nibbles

- should be able to convert back and forth to byte arrays

## Nibbles can be compared

- equal
- greater
- longer, same prefix
- less
- shorter, same prefix

## Nibble manipulation

- replace high nibble

## Hash single elements

- #nul
- #leaf
- #branch
- #hash

## Hashes

- New Trie
- One leaf
- One leaf with a big value
- Two big values: ext->branch(val1)->leaf(val2)
- Two small values: ext->branch()->leaf(val1)/leaf(val2)
- Two small values: branch()->leaf(val1)/leaf(val2)
- keep short rlp encoded values, hash long values


# Basic Trie Tests


## put

- trie is not empty after put
- get missing path
- get existing path with branch
- get existing path with branch
- extension -> branch -> 3 leafs
- Different order should produce the same trie
- Reinsert shouldn't change the trie

## iter

- Get all key value pairs

## simple save and retrieve

- save a value
- should get a value
- should update a value
- should delete a value
- should recreate a value
- should get updated a value
- should create a branch here
- should get a value that is in a branch
- should delete from a branch

## storing longer values

- should store a longer string
- should retrieve a longer value
- should when being modified delete the old value

## testing extensions and branches

- should store a value
- should create extension to store this value
- should store this value under the extension

## testing extensions and branches - reverse

- should create extension to store this value
- should store a value
- should store this value under the extension


# proof helper functions


## serialize

- serialize leaf
- deserialize leaf


# Proofs


## simple merkle proofs generation and verification


## create a merkle proof and verify it

- create a proof
- verify proofs
- Expected value at 'key2' to be null
- Expected value for a random key to be null
- extra nodes are just ignored
- to fail our proof we can request a proof for one key, and try to use that proof on another key
- we can also corrupt a valid proof
- test an invalid exclusion proof by creating a valid exclusion proof (and later making it non-null)
- now make the key non-null so the exclusion proof becomes invalid
- create a merkle proof and verify it with a single long key
- create a merkle proof and verify it with a single short key
- create a merkle proof and verify it whit keys in the middle 
- should succeed with a simple embedded extension-branch


# TrieWithDB

- put


# EthereumJS tests withDB


## simple save and retrieve

- save a value
- should get a value
- should update a value
- should delete a value
- should recreate a value
- should get updated a value
- should create a branch here
- should get a value that is in a branch
- should delete from a branch

## storing longer values

- should store a longer string
- should retrieve a longer value
- should when being modified delete the old value

## testing extensions and branches

- should store a value
- should create extension to store this value
- should store this value under the extension

## testing extensions and branches - reverse

- should create extension to store this value
- should store a value
- should store this value under the extension


# official tests

- emptyValues
- branchingTests
- jeff
- insert_middle_leaf
- branch_value_update


# Test result

    ┌─────────────────────╖
    │ ✅ All tests passed ║
    ╘═════════════════════╝

