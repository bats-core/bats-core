#!/usr/bin/env bash

set -e

BATS_ROOT="${0%/*}"
PREFIX="$1"

if [[ -z "$PREFIX" ]]; then
  printf '%s\n' \
    "usage: $0 <prefix>" \
    "  e.g. $0 /usr/local" >&2
  exit 1
fi

d="$PREFIX/bin"
for elt in "$BATS_ROOT/bin"/*; do
  elt=${elt##*/}
  rm -f "$d/$elt"
done

d="$PREFIX/libexec/bats-core"
for elt in "$BATS_ROOT/libexec/bats-core"/*; do
  elt=${elt##*/}
  rm -f "$d/$elt"
done
[[ -d "$d" ]] && rmdir "$d"

d="$PREFIX/lib/bats-core"
for elt in "$BATS_ROOT/lib/bats-core"/*; do
  elt=${elt##*/}
  rm -f "$d/$elt"
done
[[ -d "$d" ]] && rmdir "$d"

rm -f "$PREFIX"/share/man/man1/bats.1
rm -f "$PREFIX"/share/man/man7/bats.7

echo "Uninstalled Bats from $PREFIX/bin/bats"
