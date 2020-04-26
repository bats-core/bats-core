#!/usr/bin/env bash

BATS_TEST_DIRNAME="${BATS_TEST_FILENAME%/*}"
BATS_TEST_NAMES=()

# Shorthand for source-ing files relative to the BATS_TEST_DIRNAME,
# optionally with a .bash suffix appended. If the argument doesn't
# resolve relative to BATS_TEST_DIRNAME it is sourced as-is.
load() {
  local file="${1:?}"

  # For backwards-compatibility first look for a .bash-suffixed file.
  # TODO consider flipping the order here; it would be more consistent
  # and less surprising to look for an exact-match first.
  if [[ -f "${BATS_TEST_DIRNAME}/${file}.bash" ]]; then
    file="${BATS_TEST_DIRNAME}/${file}.bash"
  elif [[ -f "${BATS_TEST_DIRNAME}/${file}" ]]; then
    file="${BATS_TEST_DIRNAME}/${file}"
  fi

  if [[ ! -f "$file" ]] && ! type -P "$file" >/dev/null; then
    printf 'bats: %s does not exist\n' "$file" >&2
    exit 1
  fi

  # Dynamically loaded user file provided outside of Bats.
  # Note: 'source "$file" || exit' doesn't work on bash3.2.
  # shellcheck disable=SC1090
  source "${file}"
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
