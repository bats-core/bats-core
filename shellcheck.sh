#!/usr/bin/env bash

set -e

targets=()
while IFS=  read -r -d $'\0'; do
    targets+=("$REPLY")
done < <(
  find \
    . \
    -type f \
    \( -name \*.bash -o -name \*.sh -o -name \*.bats \) \
    -not -name "*_no_shellcheck*" \
    -print0
  )

LC_ALL=C.UTF-8 shellcheck "${targets[@]}"

exit $?
