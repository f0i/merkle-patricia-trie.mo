import TrieSpec "trie/trie.spec";
import TrieSpecWithDB "trie/withDb.spec";
import NibbleSpec "util/nibble.spec";
import KeySpec "trie/key.spec";
import ProofSpec "trie/proof.spec";
import { done } "Test";

KeySpec.tests();
NibbleSpec.tests();

TrieSpec.hashTests();
TrieSpec.basicTests();
TrieSpec.ethereumJsTests();

ProofSpec.tests();
ProofSpec.ethereumjsTests();

TrieSpecWithDB.testWithDB();

done();
