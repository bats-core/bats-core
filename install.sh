#!/usr/bin/env bash
set -e

resolve_link() {
  $(type -p greadlink readlink | head -n1) "$1"
}

abs_dirname() {
  local cwd="$(pwd)"
  local path="$1"

  while [ -n "$path" ]; do
    cd "${path%/*}"
    local name="${path##*/}"
    path="$(resolve_link "$name" || true)"
  done

  pwd
  cd "$cwd"
}

help() {
  echo "usage: $0 <installation_dir>"
  echo "  e.g. $0 /usr/local"
}

if [[ "$#" -ne 1 ]]; then
  echo "one argument expected, got $#" >&2
  help >&2
  exit 1
elif [[ "$1" == '-h' || "$1" == '--help' ]]; then
  help
  exit
elif [[ "$1" =~ ^- ]]; then
  echo "bad option: $1" >&2
  help >&2
  exit 1
else
  PREFIX="$1"
fi

BATS_ROOT="$(abs_dirname "$0")"
mkdir -p "$PREFIX"/{bin,libexec,share/man/man{1,7}}
cp -R "$BATS_ROOT"/bin/* "$PREFIX"/bin
cp -R "$BATS_ROOT"/libexec/* "$PREFIX"/libexec
cp "$BATS_ROOT"/man/bats.1 "$PREFIX"/share/man/man1
cp "$BATS_ROOT"/man/bats.7 "$PREFIX"/share/man/man7

# fix broken symbolic link file
if [ ! -L "$PREFIX"/bin/bats ]; then
    dir="$(readlink -e "$PREFIX")"
    rm -f "$dir"/bin/bats
    ln -s "$dir"/libexec/bats "$dir"/bin/bats
fi

# fix file permission
chmod a+x "$PREFIX"/bin/*
chmod a+x "$PREFIX"/libexec/*

echo "Installed Bats to $PREFIX/bin/bats"
