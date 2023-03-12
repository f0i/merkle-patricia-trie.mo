#!/usr/bin/env bash

set -eu -o pipefail

find test -name "*.spec.mo"

#for i in $(find test -name "*.spec.mo"); do
#	$(vessel bin)/moc $(vessel sources) -r "$i"
#done

$(vessel bin)/moc $(vessel sources) -r "test/index.spec.mo"
