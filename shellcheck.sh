#!/usr/bin/env bash
set -e

targets=$(find . -type f \( -name '*.bash' -o -name '*.sh' -o -name '*.bats' -not -name '*_no_shellcheck*' \) -print0)

if [[ $1 == --list ]]; then
    printf "%s\n" "${targets[@]}"
    exit 0
fi

LC_ALL=C.UTF-8 shellcheck ${targets}
