import Trietest "../fixtures/trietest";
import { chapter; section; test } "../Test";
import Text "mo:base/Text";
import Trie "../../src/Trie";
import Hex "../../src/util/Hex";
import { unwrapOpt; unwrap } "../../src/util";
import Value "../../src/Value";
import Option "mo:base/Option";
import Key "../../src/Key";
import Debug "mo:base/Debug";
import TrieMap "mo:base/TrieMap";
import Hash "../../src/Hash";

module {
    type Value = Value.Value;
    type Hash = Hash.Hash;

    public func tests() {
        chapter "official tests";
        do {

            for ((name, testData) in Trietest.data.tests.vals()) {
                var trie = Trie.init();
                var trieWithDB = Trie.init();
                var db = TrieMap.TrieMap<Hash, Trie.Node>(Hash.equal, Hash.hash);

                test name;
                let inputs = testData.input;
                let expect = testData.root;

                for ((keyData, value) in inputs.vals()) {
                    let key = unwrapOpt(Key.fromHexOrText(keyData));
                    switch (value) {
                        case (?val) {
                            let bin : Value = unwrapOpt(Value.fromHexOrText(val));
                            //Debug.print("put " # Key.toText(key) # ": " # Value.toHex(bin));
                            trie := Trie.put(trie, key, bin);
                            trieWithDB := unwrap(Trie.putWithDB(trie, key, bin, db));
                        };
                        case (null) {
                            //Debug.print("delete " # Key.toText(key));
                            trie := Trie.delete(trie, key);
                        };
                    };
                };

                //Debug.print("actual hash   " # Trie.hashHex(trie));
                //Debug.print("expected hash " # expect);
                assert Trie.hashHex(trie) == expect;
                //TODO: assert Trie.hashHex(trieWithDB) == expect;
            };
        };
    };

    /*
    tape(
        'official tests any order ', async function(t) {
            const jsonTests = require('./fixtures/trieanyorder.json').tests
            const testNames = Object.keys(jsonTests)
            let trie = new Trie() for (const testName of testNames) {
                const test = jsonTests[testName] const keys = Object.keys(test.in) let key : any for (key of keys) {
                    let val = test.in [key]

                    if (key.slice(0, 2) == = '0x') {
                        key = Buffer.from(key.slice(2), 'hex');
                    };

                    if (val != = undefined && val != = null && val.slice(0, 2) === '0x') {
                        val = Buffer.from(val.slice(2), 'hex');
                    };

                    await trie.put(Buffer.from(key), Buffer.from(val));
                };
                t.equal('0x' + trie.root().toString('hex'), test.root)
                trie = new Trie();
            };
            t.end();
        };
    );
*/

};
