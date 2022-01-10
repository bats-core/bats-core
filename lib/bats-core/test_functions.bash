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

bats_redirect_stderr_into_file() {
  "$@" 2>>"$bats_run_separate_stderr_file" # use >> to see collisions' content
}

bats_merge_stdout_and_stderr() {
  "$@" 2>&1
}

# write separate lines from <input-var> into <output-array>
bats_separate_lines() { # <output-array> <input-var>
  local output_array_name="$1"
  local input_var_name="$2"
  if [[ $keep_empty_lines ]]; then
    local bats_separate_lines_lines=()
    while IFS= read -r line; do
      bats_separate_lines_lines+=("$line")
    done <<<"${!input_var_name}"
    eval "${output_array_name}=(\"\${bats_separate_lines_lines[@]}\")"
  else
    # shellcheck disable=SC2034,SC2206
    IFS=$'\n' read -d '' -r -a "$output_array_name" <<<"${!input_var_name}" || true # don't fail due to EOF
  fi
}

run() { # [!|-N] [--keep-empty-lines] [--separate-stderr] [--] <command to run...>
  # This has to be restored on exit from this function to avoid leaking our trap INT into surrounding code.
  # Non zero exits won't restore under the assumption that they will fail the test before it can be aborted,
  # which allows us to avoid duplicating the restore code on every exit path
  trap bats_interrupt_trap_in_run INT
  local expected_rc=
  local keep_empty_lines=
  local output_case=merged
  # parse options starting with -
  while [[ $# -gt 0 ]] && [[ $1 == -* || $1 == '!' ]]; do
    case "$1" in
      '!')
        expected_rc=-1
      ;;
      -[0-9]*)
        expected_rc=${1#-}
        if [[ $expected_rc =~ [^0-9] ]]; then
          printf "Usage error: run: '=NNN' requires numeric NNN (got: %s)\n" "$expected_rc" >&2
          return 1
        elif [[ $expected_rc -gt 255 ]]; then
          printf "Usage error: run: '=NNN': NNN must be <= 255 (got: %d)\n" "$expected_rc" >&2
          return 1
        fi
      ;;
      --keep-empty-lines)
        keep_empty_lines=1
      ;;
      --separate-stderr)
        output_case="separate"
      ;;
      --)
        shift # eat the -- before breaking away
        break
      ;;
      *)
        printf "Usage error: unknown flag '%s'" "$1" >&2
        return 1
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
  esac

  local origFlags="$-"
  set +eET
  local origIFS="$IFS"
  if [[ $keep_empty_lines ]]; then
    # 'output', 'status', 'lines' are global variables available to tests.
    # preserve trailing newlines by appending . and removing it later
    # shellcheck disable=SC2034
    output="$($pre_command "$@"; status=$?; printf .; exit $status)" && status=0 || status=$?
    output="${output%.}"
  else
    # 'output', 'status', 'lines' are global variables available to tests.
    # shellcheck disable=SC2034
    output="$($pre_command "$@")" && status=0 || status=$?
  fi

  bats_separate_lines lines output

  if [[ "$output_case" == separate ]]; then
      # shellcheck disable=SC2034
      read -d '' -r stderr < "$bats_run_separate_stderr_file"
      bats_separate_lines stderr_lines stderr
  fi

  # shellcheck disable=SC2034
  BATS_RUN_COMMAND="${*}"
  IFS="$origIFS"
  set "-$origFlags"

  if [[ ${BATS_VERBOSE_RUN:-} ]]; then
    printf "%s\n" "$output" 
  fi

  if [[ -n "$expected_rc" ]]; then
    if [[ "$expected_rc" = "-1" ]]; then
      if [[ "$status" -eq 0 ]]; then
        BATS_ERROR_SUFFIX=", expected nonzero exit code!"
        return 1
      fi
    elif [ "$status" -ne "$expected_rc" ]; then
      # shellcheck disable=SC2034
      BATS_ERROR_SUFFIX=", expected exit code $expected_rc, got $status"
      return 1
    fi
  fi
  # don't leak our trap into surrounding code
  trap bats_interrupt_trap INT
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
