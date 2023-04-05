# Tests

All tests should be added to `index.spec.mo`.

## EthereumJS tests

The following tests are included in the [EthereumJs repo](https://github.com/ethereumjs/ethereumjs-monorepo/blob/master/packages/trie/test):

- encoding.spec.ts: not relevant, covers conversion between hex and javascript Buffer.
- index.spec.ts: replicated in `trie/trie.spec.mo` as well as `trie/withDB.spec.mo`
- official.spec.ts: TBD
- proof.spec.ts: replicated in `trie/proof.spec.mo`
- stream.spec.ts: not relevant, covers streaming and checkpoints

