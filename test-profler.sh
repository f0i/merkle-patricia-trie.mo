#!/usr/bin/env bash

set -eu -o pipefail

wd="$PWD"

# compile wasm
$(vessel bin)/moc $(vessel sources) -c test/performance.mo -wasi-system-api

# add profiling
cd ../motoko/wasm-profiler
cargo run -- \
    -i ../../merkle-patricia-trie.mo/performance.wasm \
    -o /tmp/instrumented.wasm \
    --wasi-system-api

time (wasmtime /tmp/instrumented.wasm > /tmp/instrumentation.out)

time (./wasm-profiler-postproc.pl flamegraph /tmp/instrumented.wasm < /tmp/instrumentation.out > /tmp/p.flamegraph)

cd ../../FlameGraph/
./flamegraph.pl < /tmp/p.flamegraph > /tmp/flamegraph.svg

cd "$wd"
mv /tmp/flamegraph.svg ./

echo "done"