#!/usr/bin/env bash

BATS_TEST_DIRNAME="${BATS_TEST_FILENAME%/*}"
BATS_TEST_NAMES=()

# _load expects an absolute path to a file or directory to source.
# If the argument is a file the file will be sourced or the same path
# with the added suffix `.bash` exists it will be sourced.
# If the argument is a directory _load checks of the file `load` or
# `load.bash` inside - if it exists this file is loaded. If it doesn't
# exist all files with the `.bash` suffix are sourced.
#
# Order with `/path/to/example` as argument:
#  - /path/to/example.bash
#  - /path/to/example
#  - /path/to/example/load.bash
#  - /path/to/example/load
#  - /path/to/example/*.bash
_load() {
    local file="${1:?}"

    if [[ "${file:0:1}" != "/" ]]; then
        printf "Received argument with a relative path, expected absolute: %s\n" "$file" >&2
        return 1
    fi

    local -a opts=(
        "$file.bash"
        "$file"
        "$file/load.bash"
        "$file/load"
    )

    for opt in "${opts[@]}"; do
        if [[ -f "$opt" ]]; then
            if ! source "$opt"; then
                printf 'Sourcing file "%s" failed' "$contained" >&2
                return 1
            fi
            return
        fi
    done

    if [[ -d "$file" ]]; then
        for contained in "$file"/*.bash; do
            if ! source "$contained"; then
                printf 'Sourcing file "%s" failed' "$contained" >&2
                return 1
            fi
        done
        return
    fi

    return 1
}

# Shorthand to source files relative to the test file
# (BATS_TEST_DIRNAME) and from BATS_LIB_PATH.
load() {
  local file="${1:?}"

  # Check if target is absolute
  if [[ "${file:0:1}" == "/" ]]; then
    if ! _load "$file"; then
      printf "Failed to load file or library '%s'\n" "$file" >&2
      return 1
    fi
    return
  fi

  local bats_lib_path="$BATS_LIB_PATH"
  if [[ -z "$bats_lib_path" ]]; then
    bats_lib_path="$HOME/.bats/lib:/usr/lib/bats"
  fi
  bats_lib_path="$BATS_TEST_DIRNAME:$bats_lib_path"

  local -a parts
  IFS=: read -ra parts <<< "$bats_lib_path"

  for part in "${parts[@]}"; do
    if _load "$part/$file"; then
      # _load finished without error, file/library was sourced, return
      return
    fi
  done

  printf "Failed to load file or library based on argument '%s'\n" "$file" >&2
  return 1
}

run() {
  local origFlags="$-"
  set +eET
  local origIFS="$IFS"
  # 'output', 'status', 'lines' are global variables available to tests.
  # shellcheck disable=SC2034
  output="$("$@" 2>&1)"
  # shellcheck disable=SC2034
  status="$?"
  # shellcheck disable=SC2034,SC2206
  IFS=$'\n' lines=($output)
  IFS="$origIFS"
  set "-$origFlags"
}

setup() {
  return 0
}

teardown() {
  return 0
}

skip() {
  # if this is a skip in teardown ...
  if [[ -n "$BATS_TEARDOWN_STARTED" ]]; then
    # ... we want to skip the rest of teardown.
    # communicate to bats_exit_trap that the teardown was completed without error
    # shellcheck disable=SC2034
    BATS_TEARDOWN_COMPLETED=1
    # if we are already in the exit trap (e.g. due to previous skip) ...
    if [[ "$BATS_TEARDOWN_STARTED" == as-exit-trap ]]; then
      # ... we need to do the rest of the tear_down_trap that would otherwise be skipped after the next call to exit
      bats_exit_trap
      # and then do the exit (at the end of this function)
    fi
    # if we aren't in exit trap, the normal exit handling should suffice
  else
    # ... this is either skip in test or skip in setup.
    # Following variables are used in bats-exec-test which sources this file
    # shellcheck disable=SC2034
    BATS_TEST_SKIPPED="${1:-1}"
    # shellcheck disable=SC2034
    BATS_TEST_COMPLETED=1
  fi
  exit 0
}

bats_test_begin() {
  BATS_TEST_DESCRIPTION="$1"
  if [[ -n "$BATS_EXTENDED_SYNTAX" ]]; then
    printf 'begin %d %s\n' "$BATS_TEST_NUMBER" "$BATS_TEST_DESCRIPTION" >&3
  fi
  setup
}

bats_test_function() {
  local test_name="$1"
  BATS_TEST_NAMES+=("$test_name")
}
