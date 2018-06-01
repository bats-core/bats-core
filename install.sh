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

# performs chmod a+x for all files in $target/$folder 
# that exist in $src/$folder
# 
# Example:
#     fix_folder_file_permissions $src $target $folder
#
fix_folder_file_permissions() {
  src=$1
  target=$2
  folder=$3
  # scan $src directory for the filenames to fix in $target
  directory="${src}/${folder}"
  for f in "${directory}"/*; do
    # get basename of file (strip the path)
    filename="${f##*/}"
    # change the execution bit for the file in $target
    chmod a+x "${target}/${folder}/$filename"
  done
}

# executes fix_folder_file_permissions for the folders
# bin and libexec.
#
# Example: 
#     fix_installed_file_permissions "${BATS_ROOT}" "${PREFIX}"
# 
fix_installed_file_permissions() {
  src=$1
  target=$2
  # we only need to adapt execution bits for bin and libexec
  folders=(bin libexec)
  for folder in ${folders[@]}; do
    fix_folder_file_permissions "${src}" "${target}" "${folder}"
  done
}

PREFIX="$1"
if [ -z "$1" ]; then
  { echo "usage: $0 <prefix>"
    echo "  e.g. $0 /usr/local"
  } >&2
  exit 1
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

fix_installed_file_permissions "${BATS_ROOT}" "${PREFIX}"

echo "Installed Bats to $PREFIX/bin/bats"
