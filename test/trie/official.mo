import Trietest "../fixtures/trietest";
import { chapter; section; test } "../Test";
import Text "mo:base/Text";
import Trie "../../src/Trie";
import TrieDB "../../src/TrieWithDB";
import TrieInternal "../../src/internal/TrieInternal";
import Hex "../../src/util/Hex";
import { unwrapOpt; unwrap } "../../src/util";
import Value "../../src/Value";
import Option "mo:base/Option";
import Key "../../src/Key";
import Debug "mo:base/Debug";
import TrieMap "mo:base/TrieMap";
import Hash "../../src/Hash";
import Time "mo:base/Time";
import Int "mo:base/Int";
import Prim "mo:prim";
import Trieanyorder "../fixtures/trieanyorder";

module {
    type Value = Value.Value;
    type Hash = Hash.Hash;

    public func tests() {
        chapter "official tests from Ethereum";

        section "official tests";
        do {
            for ((name, testData) in Trietest.data.tests.vals()) {
                test name;

                var trie = Trie.init();
                var trieWithDB = Trie.init();
                var db = TrieMap.TrieMap<Hash, TrieInternal.Node>(Hash.equal, Hash.hash);

                let inputs = testData.input;
                let expect = testData.root;

                for ((keyData, value) in inputs.vals()) {
                    let key = unwrapOpt(Key.fromHexOrText(keyData));
                    switch (value) {
                        case (?val) {
                            let bin : Value = unwrapOpt(Value.fromHexOrText(val));
                            //Debug.print("put " # Key.toText(key) # ": " # Value.toHex(bin));
                            trie := Trie.put(trie, key, bin);
                            trieWithDB := unwrap(TrieDB.put(trieWithDB, key, bin, db));
                        };
                        case (null) {
                            //Debug.print("delete " # Key.toText(key));
                            trie := Trie.delete(trie, key);
                            trieWithDB := unwrap(TrieDB.delete(trieWithDB, key, db));
                        };
                    };
                    //Debug.print("---------------------");
                    //Debug.print(Trie.nodeToText(trie));
                    //Debug.print(Trie.nodeToTextWithDB(trieWithDB, db));
                    assert Trie.toText(trie) == TrieDB.toText(trieWithDB, db);
                };

                //Debug.print("---------------------");
                //Debug.print(Trie.nodeToText(trie));
                //Debug.print(Trie.nodeToTextWithDB(trieWithDB, db));
                //Debug.print("actual hash   " # Trie.hashHex(trie));
                //Debug.print("hash withDB   " # Trie.hashHex(trieWithDB));
                //Debug.print("expected hash " # expect);
                //Debug.print("---------------------");
                //for ((k, v) in Trie.toIter(trie)) {
                //    Debug.print("entry " # Key.toText(k) # ": " # Value.toHex(v));
                //};

                assert Trie.hashHex(trie) == expect;
                assert Trie.hashHex(trieWithDB) == expect;
            };
        };

        let a = Prim.rts_heap_size();

        section "official tests any order";
        do {
            for ((name, testData) in Trieanyorder.data.tests.vals()) {
                test name;

                var trie = Trie.init();
                var trieWithDB = Trie.init();
                var db = TrieMap.TrieMap<Hash, TrieDB.Node>(Hash.equal, Hash.hash);

                let inputs = testData.input;
                let expect = testData.root;

                for ((keyData, value) in inputs.vals()) {
                    let key = unwrapOpt(Key.fromHexOrText(keyData));
                    switch (value) {
                        case (?val) {
                            let bin : Value = unwrapOpt(Value.fromHexOrText(val));
                            //Debug.print("put " # Key.toText(key) # ": " # Value.toHex(bin));
                            trie := Trie.put(trie, key, bin);
                            trieWithDB := unwrap(TrieDB.put(trieWithDB, key, bin, db));
                        };
                        case (null) {
                            //Debug.print("delete " # Key.toText(key));
                            trie := Trie.delete(trie, key);
                            trieWithDB := unwrap(TrieDB.delete(trieWithDB, key, db));
                        };
                    };
                    assert Trie.toText(trie) == TrieDB.toText(trieWithDB, db);
                };

                assert Trie.hashHex(trie) == expect;
                assert Trie.hashHex(trieWithDB) == expect;
            };
        };

    };

};
