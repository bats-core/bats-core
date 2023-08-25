#!/usr/bin/env bash

set -e

BATS_ROOT="${0%/*}"
PREFIX="${1%/}"
LIBDIR="${2}"

if [[ -z "$PREFIX" ]]; then
  printf '%s\n' \
    "usage: $0 <prefix> [base_libdir]" \
    "  e.g. $0 /usr/local" \
    "       $0 /usr/local lib64" >&2
  exit 1
fi

if [[ ! -d "$PREFIX" ]]; then
  printf "No valid installation in directory %s.\n" "$PREFIX"
  exit 2
fi

LIBDIR=$(grep -e '^BATS_BASE_LIBDIR=' "$PREFIX/bin/bats")
eval "$LIBDIR"
LIBDIR="${BATS_BASE_LIBDIR:-lib}"

d="$PREFIX/bin"
for elt in "$BATS_ROOT/bin"/*; do
  elt=${elt##*/}
  echo "Removing $d/$elt"
  rm -f "$d/$elt"
done

d="$PREFIX/libexec/bats-core"
for elt in "$BATS_ROOT/libexec/bats-core"/*; do
  elt=${elt##*/}
  echo "Removing $d/$elt"
  rm -f "$d/$elt"
done
[[ -d "$d" ]] && echo "Removing $d" && rmdir "$d"

d="$PREFIX/${LIBDIR}/bats-core"
for elt in "$BATS_ROOT/lib/bats-core"/*; do
  elt=${elt##*/}
  echo "Removing $d/$elt"
  rm -f "$d/$elt"
done
[[ -d "$d" ]] && echo "Removing $d" && rmdir "$d"

echo "Removing $PREFIX"/share/man/man1/bats.1"
rm -f "$PREFIX"/share/man/man1/bats.1

echo "Removing $PREFIX"/share/man/man1/bats.7"
rm -f "$PREFIX"/share/man/man7/bats.7

echo "Uninstalled Bats from $PREFIX/bin/bats"
