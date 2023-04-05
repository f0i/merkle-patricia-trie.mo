import TrieSpec "trie/trie.spec";
import NibbleSpec "util/nibble.spec";
import KeySpec "trie/key.spec";
import ProofSpec "trie/proof.spec";
import { done } "Test";

KeySpec.tests();
NibbleSpec.tests();

TrieSpec.ethereumJsTests();

ProofSpec.tests();

done();
