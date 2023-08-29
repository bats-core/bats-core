#!/usr/bin/env bats

load test_helper

INSTALL_DIR=
PATH_TO_INSTALL_SHELL=
PATH_TO_UNINSTALL_SHELL=

setup() {
  INSTALL_DIR="$BATS_TEST_TMPDIR/bats-core"
  PATH_TO_INSTALL_SHELL="${BATS_TEST_DIRNAME%/*}/install.sh"
  PATH_TO_UNINSTALL_SHELL="${BATS_TEST_DIRNAME%/*}/uninstall.sh"
}

@test "install.sh creates a valid installation, and uninstall.sh undos it" {
  run "$PATH_TO_INSTALL_SHELL" "$INSTALL_DIR"
  [ "$status" -eq 0 ]
  [ "$output" == "Installed Bats to $INSTALL_DIR/bin/bats" ]
  [ -x "$INSTALL_DIR/bin/bats" ]
  [ -x "$INSTALL_DIR/$BATS_LIBDIR/bats-core/formatter.bash" ]
  [ -x "$INSTALL_DIR/$BATS_LIBDIR/bats-core/preprocessing.bash" ]
  [ -x "$INSTALL_DIR/$BATS_LIBDIR/bats-core/semaphore.bash" ]
  [ -x "$INSTALL_DIR/$BATS_LIBDIR/bats-core/test_functions.bash" ]
  [ -x "$INSTALL_DIR/$BATS_LIBDIR/bats-core/tracing.bash" ]
  [ -x "$INSTALL_DIR/$BATS_LIBDIR/bats-core/validator.bash" ]
  [ -x "$INSTALL_DIR/libexec/bats-core/bats" ]
  [ -x "$INSTALL_DIR/libexec/bats-core/bats-exec-suite" ]
  [ -x "$INSTALL_DIR/libexec/bats-core/bats-exec-test" ]
  [ -x "$INSTALL_DIR/libexec/bats-core/bats-format-junit" ]
  [ -x "$INSTALL_DIR/libexec/bats-core/bats-format-pretty" ]
  [ -x "$INSTALL_DIR/libexec/bats-core/bats-preprocess" ]
  [ -f "$INSTALL_DIR/share/man/man1/bats.1" ]
  [ -f "$INSTALL_DIR/share/man/man7/bats.7" ]

  reentrant_run "$INSTALL_DIR/bin/bats" -v
  [ "$status" -eq 0 ]
  [ "${output%% *}" == 'Bats' ]

  run "$PATH_TO_UNINSTALL_SHELL" "$INSTALL_DIR"
  [ "$status" -eq 0 ]
  [ ! -x "$INSTALL_DIR/bin/bats" ]
  [ ! -x "$INSTALL_DIR/$BATS_LIBDIR/bats-core/formatter.bash" ]
  [ ! -x "$INSTALL_DIR/$BATS_LIBDIR/bats-core/preprocessing.bash" ]
  [ ! -x "$INSTALL_DIR/$BATS_LIBDIR/bats-core/semaphore.bash" ]
  [ ! -x "$INSTALL_DIR/$BATS_LIBDIR/bats-core/test_functions.bash" ]
  [ ! -x "$INSTALL_DIR/$BATS_LIBDIR/bats-core/tracing.bash" ]
  [ ! -x "$INSTALL_DIR/$BATS_LIBDIR/bats-core/validator.bash" ]
  [ ! -x "$INSTALL_DIR/libexec/bats-core/bats" ]
  [ ! -x "$INSTALL_DIR/libexec/bats-core/bats-exec-suite" ]
  [ ! -x "$INSTALL_DIR/libexec/bats-core/bats-exec-test" ]
  [ ! -x "$INSTALL_DIR/libexec/bats-core/bats-format-junit" ]
  [ ! -x "$INSTALL_DIR/libexec/bats-core/bats-format-pretty" ]
  [ ! -x "$INSTALL_DIR/libexec/bats-core/bats-preprocess" ]
  [ ! -x "$INSTALL_DIR/libexec/bats-core" ]
  [ ! -x "$INSTALL_DIR/share/man/man1/bats.1" ]
  [ ! -x "$INSTALL_DIR/share/man/man7/bats.7" ]
}

@test "install.sh creates a multilib valid installation, and uninstall.sh undos it" {
  rm -rf "$INSTALL_DIR"
  LIBDIR="lib64"
  run "$PATH_TO_INSTALL_SHELL" "$INSTALL_DIR" "$LIBDIR"
  [ "$status" -eq 0 ]
  [ "$output" == "Installed Bats to $INSTALL_DIR/bin/bats" ]
  [ -x "$INSTALL_DIR/bin/bats" ]
  [ -x "$INSTALL_DIR/$LIBDIR/bats-core/formatter.bash" ]
  [ -x "$INSTALL_DIR/$LIBDIR/bats-core/preprocessing.bash" ]
  [ -x "$INSTALL_DIR/$LIBDIR/bats-core/semaphore.bash" ]
  [ -x "$INSTALL_DIR/$LIBDIR/bats-core/test_functions.bash" ]
  [ -x "$INSTALL_DIR/$LIBDIR/bats-core/tracing.bash" ]
  [ -x "$INSTALL_DIR/$LIBDIR/bats-core/validator.bash" ]
  [ -x "$INSTALL_DIR/libexec/bats-core/bats" ]
  [ -x "$INSTALL_DIR/libexec/bats-core/bats-exec-suite" ]
  [ -x "$INSTALL_DIR/libexec/bats-core/bats-exec-test" ]
  [ -x "$INSTALL_DIR/libexec/bats-core/bats-format-junit" ]
  [ -x "$INSTALL_DIR/libexec/bats-core/bats-format-pretty" ]
  [ -x "$INSTALL_DIR/libexec/bats-core/bats-preprocess" ]
  [ -f "$INSTALL_DIR/share/man/man1/bats.1" ]
  [ -f "$INSTALL_DIR/share/man/man7/bats.7" ]

  reentrant_run "$INSTALL_DIR/bin/bats" -v
  [ "$status" -eq 0 ]
  [ "${output%% *}" == 'Bats' ]

  run "$PATH_TO_UNINSTALL_SHELL" "$INSTALL_DIR" "$LIBDIR"
  [ "$status" -eq 0 ]
  [ ! -x "$INSTALL_DIR/bin/bats" ]
  [ ! -x "$INSTALL_DIR/$LIBDIR/bats-core/formatter.bash" ]
  [ ! -x "$INSTALL_DIR/$LIBDIR/bats-core/preprocessing.bash" ]
  [ ! -x "$INSTALL_DIR/$LIBDIR/bats-core/semaphore.bash" ]
  [ ! -x "$INSTALL_DIR/$LIBDIR/bats-core/test_functions.bash" ]
  [ ! -x "$INSTALL_DIR/$LIBDIR/bats-core/tracing.bash" ]
  [ ! -x "$INSTALL_DIR/$LIBDIR/bats-core/validator.bash" ]
  [ ! -x "$INSTALL_DIR/libexec/bats-core/bats" ]
  [ ! -x "$INSTALL_DIR/libexec/bats-core/bats-exec-suite" ]
  [ ! -x "$INSTALL_DIR/libexec/bats-core/bats-exec-test" ]
  [ ! -x "$INSTALL_DIR/libexec/bats-core/bats-format-junit" ]
  [ ! -x "$INSTALL_DIR/libexec/bats-core/bats-format-pretty" ]
  [ ! -x "$INSTALL_DIR/libexec/bats-core/bats-preprocess" ]
  [ ! -x "$INSTALL_DIR/libexec/bats-core" ]
  [ ! -x "$INSTALL_DIR/share/man/man1/bats.1" ]
  [ ! -x "$INSTALL_DIR/share/man/man7/bats.7" ]
}

@test "uninstall.sh works even if nothing is installed" {
  mkdir -p "$INSTALL_DIR"/tmp
  run "$PATH_TO_UNINSTALL_SHELL" "$INSTALL_DIR"
  [ "$status" -eq 0 ]
  rmdir "$INSTALL_DIR"/tmp
}

@test "install.sh only updates permissions for Bats files" {
  mkdir -p "$INSTALL_DIR"/{bin,libexec/bats-core}

  local dummy_bin="$INSTALL_DIR/bin/dummy"
  printf 'dummy' >"$dummy_bin"

  local dummy_libexec="$INSTALL_DIR/libexec/bats-core/dummy"
  printf 'dummy' >"$dummy_libexec"

  run "$PATH_TO_INSTALL_SHELL" "$INSTALL_DIR"
  [ "$status" -eq 0 ]
  [ -f "$dummy_bin" ]
  [ ! -x "$dummy_bin" ]
  [ -f "$dummy_libexec" ]
  [ ! -x "$dummy_libexec" ]
}

@test "bin/bats is resilient to symbolic links" {
  run "$PATH_TO_INSTALL_SHELL" "$INSTALL_DIR"
  [ "$status" -eq 0 ]

  # Simulate a symlink to bin/bats (without using a symlink, for Windows sake)
  # by creating a wrapper script that executes bin/bats via a relative path.
  #
  # root.bats contains tests that use real symlinks on platforms that support
  # them.
  local bats_symlink="$INSTALL_DIR/bin/bats-link"
  printf '%s\n' '#! /usr/bin/env bash' \
    "cd '$INSTALL_DIR/bin'" \
    './bats "$@"' >"$bats_symlink"
  chmod 700 "$bats_symlink"

  reentrant_run "$bats_symlink" -v
  [ "$status" -eq 0 ]
  [ "${output%% *}" == 'Bats' ]
}

teardown() {
  rm -rf "$INSTALL_DIR"
}
