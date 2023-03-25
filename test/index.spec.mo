import TrieSpec "trie/trie.spec";
import NibbleSpec "util/nibble.spec";
import KeySpec "trie/node/key.spec";
import ProofSpec "trie/proof.spec";
import { done } "Test";

KeySpec.tests();
NibbleSpec.tests();

TrieSpec.hashTests();
TrieSpec.basicTests();
TrieSpec.ethereumJsTests();

ProofSpec.tests();
ProofSpec.ethereumjsTests();

done();
