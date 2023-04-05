#!/usr/bin/env bash

set -eu -o pipefail

wd="$PWD"

mkdir -p "$wd/tmp/"

# compile wasm
$(vessel bin)/moc $(vessel sources) -c test/performance.mo -wasi-system-api

# add profiling
cd ../motoko/wasm-profiler
cargo run -- \
    -i "$wd/performance.wasm" \
    -o "$wd/tmp/instrumented.wasm" \
    --wasi-system-api

mv "$wd/performance.wasm" "$wd/tmp/"

time (wasmtime "$wd/tmp/instrumented.wasm" > "$wd/tmp/instrumentation.out")

time (./wasm-profiler-postproc.pl flamegraph "$wd/tmp/instrumented.wasm" < "$wd/tmp/instrumentation.out" > "$wd/tmp/p.flamegraph")

cd ../../FlameGraph/
./flamegraph.pl < "$wd/tmp/p.flamegraph" > "$wd/flamegraph.svg"

echo "done"