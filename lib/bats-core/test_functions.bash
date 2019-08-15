#!/usr/bin/env bash

BATS_TEST_DIRNAME="${BATS_TEST_FILENAME%/*}"
BATS_TEST_NAMES=()

load() {
  local name="$1"
  local filename

  if [[ "${name:0:1}" == '/' ]]; then
    filename="${name}"
  else
    filename="$BATS_TEST_DIRNAME/${name}.bash"
  fi

  if [[ ! -f "$filename" ]]; then
    printf 'bats: %s does not exist\n' "$filename" >&2
    exit 1
  fi

  # Dynamically loaded user files provided outside of Bats.
  # shellcheck disable=SC1090
  source "${filename}"
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
  # Following variables are used in bats-exec-test which sources this file
  # shellcheck disable=SC2034
  BATS_TEST_SKIPPED="${1:-1}"
  # shellcheck disable=SC2034
  BATS_TEST_COMPLETED=1
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
