#!/usr/bin/env bash

set -eu -o pipefail

for i in $(find test -name "*.spec.mo"); do
	$(vessel bin)/moc $(vessel sources) -r "$i"
done
