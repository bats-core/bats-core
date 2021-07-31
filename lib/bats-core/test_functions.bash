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

bats_suppress_stderr() {
  "$@" 2>/dev/null
}

bats_suppress_stdout() {
  # throw away stdout and redirect stderr into stdout
  # shellcheck disable=SC2069
  "$@" 2>&1 >/dev/null 
}

bats_redirect_stderr_into_file() {
  "$@" 2>>"$bats_run_separate_stderr_file" # use >> to see collisions' content
}

bats_merge_stdout_and_stderr() {
  "$@" 2>&1
}

# write separate lines from <input-var> into <output-array>
bats_separate_lines() { # <output-array> <input-var>
  output_array_name="$1"
  input_var_name="$2"
  if [[ $keep_empty_lines ]]; then
    local bats_separate_lines_lines=()
    while IFS= read -r line; do
      bats_separate_lines_lines+=("$line")
    done <<<"${!input_var_name}"
    eval "${output_array_name}=(\"\${bats_separate_lines_lines[@]}\")"
  else
    # shellcheck disable=SC2034,SC2206
    IFS=$'\n' read -d '' -r -a "$output_array_name" <<<"${!input_var_name}"
  fi
}

run() { # [--keep-empty-lines] [--output merged|separate|stderr|stdout] [--] <command to run...>
  trap bats_interrupt_trap_in_run INT
  local keep_empty_lines=
  local output_case=merged
  # parse options starting with -
  while [[ $# -gt 0 && $1 == -* ]]; do
    case "$1" in
      --keep-empty-lines)
        keep_empty_lines=1
      ;;
      --output)
        output_case="$2"
        shift 2 # consume the value too!
      ;;
      --)
        shift # eat the -- before breaking away
        break
      ;;
    esac
    shift
  done

  local pre_command=

  case "$output_case" in
    merged) # redirects stderr into stdout and fills only $output/$lines
      pre_command=bats_merge_stdout_and_stderr
    ;;
    separate) # splits stderr into own file and fills $stderr/$stderr_lines too
      local bats_run_separate_stderr_file
      bats_run_separate_stderr_file="$(mktemp "${BATS_TEST_TMPDIR}/separate-stderr-XXXXXX")"
      pre_command=bats_redirect_stderr_into_file
    ;;
    stderr) # suppresses stdout and fills $stderr/$stderr_lines
      pre_command=bats_suppress_stdout
    ;;
    stdout) # suppresses stderr and fills $output/$lines
      pre_command=bats_suppress_stderr
    ;;
    *)
      printf "ERROR: Unknown --output value %s" "$output_case"
      return 1
    ;;
  esac

  local origFlags="$-"
  set -f +eET
  local origIFS="$IFS"
  if [[ $keep_empty_lines ]]; then
    # 'output', 'status', 'lines' are global variables available to tests.
    # preserve trailing newlines by appending . and removing it later
    # shellcheck disable=SC2034
    output="$($pre_command "$@"; status=$?; printf .; exit $status)"
    # shellcheck disable=SC2034
    status="$?"
    output="${output%.}"
  else
    # 'output', 'status', 'lines' are global variables available to tests.
    # shellcheck disable=SC2034
    output="$($pre_command "$@")"
    # shellcheck disable=SC2034
    status="$?"
  fi

  bats_separate_lines lines output

  case "$output_case" in
    stderr)
      stderr="$output"
      # shellcheck disable=SC2034
      stderr_lines=("${lines[@]}")
      unset output
      unset lines
    ;;
    separate)
      # shellcheck disable=SC2034
      read -d '' -r stderr < "$bats_run_separate_stderr_file"
      bats_separate_lines stderr_lines stderr
    ;;
  esac

  # shellcheck disable=SC2034
  BATS_TEST_COMMAND="${*}"
  if $VERBOSE; then
    printf "  %s\n" "${BATS_TEST_COMMAND}" >&3
    printf "    %s\n" "${lines[@]:-}" >&3
  fi
  
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
  if [[ -n "${BATS_TEARDOWN_STARTED-}" ]]; then
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
    printf 'begin %d %s\n' "$BATS_SUITE_TEST_NUMBER" "$BATS_TEST_DESCRIPTION" >&3
  fi
  setup
}

bats_test_function() {
  local test_name="$1"
  BATS_TEST_NAMES+=("$test_name")
}
