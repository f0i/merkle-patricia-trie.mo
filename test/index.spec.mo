import TrieSpec "trie/trie.spec";
import TrieSpecWithDB "trie/withDB.spec";
import NibbleSpec "util/nibble.spec";
import KeySpec "trie/key.spec";
import ProofSpec "trie/proof.spec";
import { start; done } "Test";
import Official "trie/official";

start();

KeySpec.tests();
NibbleSpec.tests();

TrieSpec.hashTests();
TrieSpec.basicTests();
TrieSpec.ethereumJsTests();

ProofSpec.tests();
ProofSpec.ethereumjsTests();

TrieSpecWithDB.tests();
TrieSpecWithDB.ethereumJsTests();

Official.tests();

done();
