import TrieSpec "trie/trie.spec";
import NibbleSpec "util/nibble.spec";
import KeySpec "trie/node/key.spec";
import ProofSpec "trie/proof.spec";

KeySpec.tests();

NibbleSpec.tests();

TrieSpec.hashTests();
TrieSpec.ethereumJsTests();
TrieSpec.basicTests();

ProofSpec.ethereumjsTests();
