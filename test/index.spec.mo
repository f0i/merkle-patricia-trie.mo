import { describe; it; itp; equal; Suite } = "mo:testing/SuiteState";

import TrieSpec "trie/trie.spec";
import NibbleSpec "util/nibble.spec";
import KeySpec "trie/node/key.spec";

type State = {};

let s = Suite<State>({});

TrieSpec.hashTests();
TrieSpec.ethereumJsTests();

await* s.run([
    TrieSpec.tests(),
    NibbleSpec.tests(),
    KeySpec.tests(),

    TrieSpec.testsFromEthereumjs(),
]);
