#!/usr/bin/env bash

set -e

targets=()
while IFS= read -r -d $'\0'; do
  targets+=("$REPLY")
done < <(
  find . -type f \( -name \*.bash -o -name \*.sh \) -print0
  find . -type f -name '*.bats' -not -name '*_no_shellcheck*' -print0
  find libexec -type f -print0
  find bin -type f -print0
)

if [[ $1 == --list ]]; then
  printf "%s\n" "${targets[@]}"
  exit 0
fi

LC_ALL=C.UTF-8 shellcheck "${targets[@]}"

exit $?
