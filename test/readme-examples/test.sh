#!/usr/bin/env bash

$(vessel bin)/moc \
    --package merkle-patricia-trie ../../src/ \
    $(mops sources) \
    -r trie.mo

$(vessel bin)/moc \
    --package merkle-patricia-trie ../../src/ \
    $(mops sources) \
    -r trieWithDB.mo
