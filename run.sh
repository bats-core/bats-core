#!/bin/bash

run_with_bash() {
  # shellcheck disable=SC2016
  echo "Running tests with bash $("$1/bash" -c 'echo $BASH_VERSION')"
  ( PATH="$1":$PATH bin/bats --tap test )
  echo
}

install_bashes() {
  for v in 3.1 3.2 4.0 4.1 4.2 4.3 4.4; do
    wget https://ftp.gnu.org/gnu/bash/bash-$v.tar.gz
    tar -xf bash-$v.tar.gz
    rm bash-$v.tar.gz

    (
      cd bash-$v
      ./configure
      make
    )

    cp -r bash-$v bash-$v-patch

    (
      cd bash-$v-patch
      wget --cut-dirs=100 -r --no-parent https://ftp.gnu.org/gnu/bash/bash-$v-patches/
      mv ftp.gnu.org bash-$v-patches/
      ( cd bash-$v-patches && cat bash??-??? ) | patch -s -p0 || exit 1
      make
    )
  done
}

for v in bash-*; do
  run_with_bash "$v"
done
