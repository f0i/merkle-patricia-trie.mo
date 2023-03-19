import { describe; it; itp; equal; Suite } = "mo:testing/SuiteState";

import TrieSpec "trie/trie.spec";
import NibbleSpec "util/nibble.spec";
import KeySpec "trie/node/key.spec";

type State = {};

let s = Suite<State>({});

TrieSpec.hashTests();
TrieSpec.ethereumJsTests();
TrieSpec.basicTests();
NibbleSpec.tests();

KeySpec.tests();
