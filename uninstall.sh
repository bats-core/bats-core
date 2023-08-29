#!/usr/bin/env bash

set -e

BATS_ROOT="${0%/*}"
PREFIX="${1%/}"

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

if [ -e "$PREFIX/bin/bats" ]; then
  LIBDIR=$(grep -e '^BATS_BASE_LIBDIR=' "$PREFIX/bin/bats")
  eval "$LIBDIR"
fi
LIBDIR="${BATS_BASE_LIBDIR:-lib}"

remove_file() { # <file>
  echo "Removing $1"
  rm -f "$1"
}

remove_directory() { # <directory>
  local directory=$1
  if [[ -d "$directory" ]]; then
    echo "Removing $directory"
    rmdir "$directory"
  fi
}

d="$PREFIX/bin"
for elt in "$BATS_ROOT/bin"/*; do
  elt=${elt##*/}
  remove_file "$d/$elt"
done

d="$PREFIX/libexec/bats-core"
for elt in "$BATS_ROOT/libexec/bats-core"/*; do
  elt=${elt##*/}
  remove_file "$d/$elt"
done
remove_directory "$d"

d="$PREFIX/${LIBDIR}/bats-core"
for elt in "$BATS_ROOT/lib/bats-core"/*; do
  elt=${elt##*/}
  remove_file "$d/$elt"
done
remove_directory "$d"

remove_file "$PREFIX"/share/man/man1/bats.1
remove_file "$PREFIX"/share/man/man7/bats.7

echo "Uninstalled Bats from $PREFIX/bin/bats"
