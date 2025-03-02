#!/usr/bin/env bats
#
# This suite is dedicated to calculating BATS_ROOT when going through various
# permutations of symlinks. It was inspired by the report in issue #113 that the
# calculation was broken on CentOS, where /bin is symlinked to /usr/bin.
#
# The basic test environment is (all paths relative to BATS_TEST_TMPDIR):
#
# - /bin is a relative symlink to /usr/bin, exercising the symlink resolution of
#   the `bats` parent directory (i.e. "${0%/*}")
# - /usr/bin/bats is an absolute symlink to /opt/bats-core/bin/bats, exercising
#   the symlink resolution of the `bats` executable itself (i.e. "${0##*/}")

load test_helper

# bats file_tags=dep:install_sh

setup() {
  # give each test their own tmpdir to allow for parallelization without interference
  # shellcheck disable=SC2103,SC2164
  cd "$BATS_TEST_TMPDIR"
  PATH_TO_INSTALL_SHELL="${BATS_TEST_DIRNAME%/*}/install.sh"
  mkdir -p {usr/bin,opt/bats-core}
  ls -lR .
  "$PATH_TO_INSTALL_SHELL" "opt/bats-core"

  ln -s "usr/bin" "bin"

  if [[ ! -L "bin" ]]; then
    # shellcheck disable=SC2103,SC2164
    cd - >/dev/null
    skip "symbolic links aren't functional on OSTYPE=$OSTYPE"
  fi

  ln -s "$BATS_TEST_TMPDIR/opt/bats-core/bin/bats" \
    "$BATS_TEST_TMPDIR/usr/bin/bats"
  # shellcheck disable=SC2103,SC2164
  cd - >/dev/null
}

@test "#113: set BATS_ROOT when /bin is a symlink to /usr/bin" {
  reentrant_run "$BATS_TEST_TMPDIR/bin/bats" -v
  [ "$status" -eq 0 ]
  [ "${output%% *}" == 'Bats' ]
}

# The resolution scheme here is:
#
# Set in setup
# - /bin => /usr/bin (relative directory)
@test "set BATS_ROOT with extreme symlink resolution" {
  # shellcheck disable=SC2103
  cd "$BATS_TEST_TMPDIR"
  mkdir -p "opt/bats/bin2"
  pwd

  # - /usr/bin/foo => /usr/bin/bar (relative executable)
  ln -s bar usr/bin/foo
  # - /usr/bin/bar => /opt/bats/bin0/bar (absolute executable)
  ln -s "$BATS_TEST_TMPDIR/opt/bats/bin0/bar" usr/bin/bar
  # - /opt/bats/bin0 => /opt/bats/bin1 (relative directory)
  ln -s bin1 opt/bats/bin0
  # - /opt/bats/bin1 => /opt/bats/bin2 (absolute directory)
  ln -s "$BATS_TEST_TMPDIR/opt/bats/bin2" opt/bats/bin1
  # - /opt/bats/bin2/bar => /opt/bats-core/bin/bar (absolute executable)
  ln -s "$BATS_TEST_TMPDIR/opt/bats-core/bin/bar" opt/bats/bin2/bar
  # - /opt/bats-core/bin/bar => /opt/bats-core/bin/baz (relative executable)
  ln -s baz opt/bats-core/bin/bar
  # - /opt/bats-core/bin/baz => /opt/bats-core/bin/bats (relative executable)
  ln -s bats opt/bats-core/bin/baz

  # shellcheck disable=SC2103,SC2164
  cd - >/dev/null
  reentrant_run "$BATS_TEST_TMPDIR/bin/foo" -v
  echo "$output"
  [ "$status" -eq 0 ]
  [ "${output%% *}" == 'Bats' ]
}

@test "set BATS_ROOT when calling from same dir" {
  cd "$BATS_TEST_TMPDIR"
  reentrant_run ./bin/bats -v
  [ "$status" -eq 0 ]
  [ "${output%% *}" == 'Bats' ]
}

@test "set BATS_ROOT from PATH" {
  cd /tmp
  # shellcheck disable=SC2031,SC2030
  PATH="$PATH:$BATS_TEST_TMPDIR/bin"
  reentrant_run bats -v
  [ "$status" -eq 0 ]
  [ "${output%% *}" == 'Bats' ]
}

@test "#182 and probably #184 as well" {
  cd /tmp
  # shellcheck disable=SC2031,SC2030
  PATH="$PATH:$BATS_TEST_TMPDIR/bin"
  reentrant_run bash bats -v
  [ "$status" -eq 0 ]
  [ "${output%% *}" == 'Bats' ]
}
