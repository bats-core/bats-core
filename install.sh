#!/usr/bin/env bash

set -e

BATS_ROOT="${0%/*}"
PREFIX="$1"
if [ -z "$1" ]; then
  { echo "usage: $0 <prefix>"
    echo "  e.g. $0 /usr/local"
  } >&2
  exit 1
fi
mkdir -p "$PREFIX"/{bin,libexec,share/man/man{1,7}}

for scripts_dir in 'bin' 'libexec'; do
  scripts=("$BATS_ROOT/$scripts_dir"/*)
  cp "${scripts[@]}" "$PREFIX/$scripts_dir"
  chmod a+x "${scripts[@]/#$BATS_ROOT[/]/$PREFIX/}"
done

cp "$BATS_ROOT/man/bats.1" "$PREFIX/share/man/man1"
cp "$BATS_ROOT/man/bats.7" "$PREFIX/share/man/man7"

echo "Installed Bats to $PREFIX/bin/bats"
