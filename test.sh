#!/usr/bin/env bash

set -eu -o pipefail

($(vessel bin)/moc $(vessel sources) -r "test/index.spec.mo" $* | tee test/RESULTS.md) \
    || (echo -e '\n\n# Test Result \n\n' | tee -a test/RESULTS.md ; false) \
    || (echo -e '    ❌ Test failed!' | tee -a test/RESULTS.md ; false) \
    || (echo -e '' | tee -a test/RESULTS.md ; false) \
