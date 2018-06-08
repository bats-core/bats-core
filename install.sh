#!/usr/bin/env bash

set -e

PREFIX="$1"
if [ -z "$1" ]; then
  { echo "usage: $0 <prefix>"
    echo "  e.g. $0 /usr/local"
  } >&2
  exit 1
fi

export BATS_READLINK='true'
if command -v 'greadlink' >/dev/null; then
  BATS_READLINK='greadlink'
elif command -v 'readlink' >/dev/null; then
  BATS_READLINK='readlink'
fi

bats_resolve_link() {
  if ! "$BATS_READLINK" "$1"; then
    return 0
  fi
}

bats_absolute_path() {
  local cwd="$PWD"
  local path="$1"
  local result="$2"

  while [[ -n "$path" ]]; do
    cd "${path%/*}"
    path="$(bats_resolve_link "${path##*/}")"
  done

  printf -v "$result" -- '%s' "$PWD"
  cd "$cwd"
}

bats_install_scripts() {
  local scripts_dir
  local scripts=()

  for scripts_dir in "$@"; do
    scripts=("$BATS_ROOT/$scripts_dir"/*)
    cp "${scripts[@]}" "$PREFIX/$scripts_dir"
    chmod a+x "${scripts[@]/#$BATS_ROOT[/]/$PREFIX/}"
  done
}

mkdir -p "$PREFIX"/{bin,libexec,share/man/man{1,7}}
bats_absolute_path "$0" 'BATS_ROOT'
bats_install_scripts 'bin' 'libexec'
cp "$BATS_ROOT/man/bats.1" "$PREFIX/share/man/man1"
cp "$BATS_ROOT/man/bats.7" "$PREFIX/share/man/man7"

echo "Installed Bats to $PREFIX/bin/bats"
