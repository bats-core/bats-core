#!/usr/bin/env bash

BATS_TEST_DIRNAME="${BATS_TEST_FILENAME%/*}"
BATS_TEST_NAMES=()

# find_library_load_path expects an absolute path as the first argument
# and echoes the first library load path for the bats library it finds.
#
# A library load path can be either a file or a directory.
#
# If library load path can not be found find_library_loader returns 1.
#
# The order for library loaders is:
#   - file: <library_path>.bash
#   - file: <library_path>
#   - file: <library_path>/load.bash
#   - file: <library_path>/load
#   - directory: <library_path>
find_library_load_path() {
  local library_path="${1:?}"

  local -a library_load_paths=(
    "$library_path.bash"
    "$library_path"
    "$library_path/load.bash"
    "$library_path/load"
  )

  for library_load_path in "${library_load_paths[@]}"; do
    if [[ -f "$library_load_path" ]]; then
      echo "$library_load_path"
      return
    fi
  done

  if [[ -d "$library_path" ]]; then
    echo "$library_path"
    return
  fi

  return 1
}

# find_in_bats_lib_path echoes the first recognized load path to
# a library in BATS_LIB_PATH or relative to BATS_TEST_DIRNAME.
#
# Libraries relative to BATS_TEST_DIRNAME take precedence over
# BATS_LIB_PATH.
#
# Library load paths are recognized using find_library_load_path.
#
# If no library is found find_in_bats_lib_path returns 1.
find_in_bats_lib_path() {
  local library_name="${1:?}"

  local bats_lib_path="${BATS_LIB_PATH:-}"
  if [[ -z "$bats_lib_path" ]]; then
    bats_lib_path="$HOME/.bats/lib:/usr/lib/bats"
  fi
  bats_lib_path="$BATS_TEST_DIRNAME:$bats_lib_path"

  local -a bats_lib_paths
  IFS=: read -ra bats_lib_paths <<< "$bats_lib_path"

  for path in "${bats_lib_paths[@]}"; do
    if find_library_load_path "$path/$library_name"; then
      # A library load path was found, return
      return
    fi
  done

  return 1
}

# _load expects an absolute path that is a library load path.
#
# If the library load path points to a file (a library loader) it is
# sourced.
#
# If it points to a directory all files ending in .bash inside of the
# directory are sourced.
#
# If the sourcing of the library loader or of a file in a library
# directory fails _load prints an error message and returns 1.
#
# If the passed library load path is not absolute or is not a valid file
# or directory _load prints an error message and returns 1.
_load() {
  local library_load_path="${1:?}"

  if [[ "${library_load_path:0:1}" != / ]]; then
    printf "Passed library load path is not an absolute path: %s\n" "$library_load_path" >&2
    return 1
  fi

  # library_load_path is a library loader
  if [[ -f "$library_load_path" ]]; then
      # shellcheck disable=SC1090
      if ! source "$library_load_path"; then
          printf "Error while sourcing library loader at '%s'\n" "$library_load_path" >&2
          return 1
      fi
      return
  fi

  # library_load_path is a library directory
  if [[ -d "$library_load_path" ]]; then
    for library_file in "$library_load_path"/*.bash; do

      # Skip over directories
      [[ -d "$library_file" ]] && continue
      # shellcheck disable=SC1090
      if ! source "$library_file"; then
        printf "Error while sourcing library file '%s'\n" "$library_file" >&2
        return 1
      fi
    done

    return
  fi

  printf "Passed library load path is neither a library loader nor library directory: %s\n" "$library_load_path" >&2
  return 1
}

# load_safe accepts an argument called 'slug' and attempts to find and
# source a library based on the slug.
#
# A slug can be an absolute path, a library name or a relative path.
#
# If the slug is an absolute path load_safe attempts to find the library
# load path using find_library_load_path.
# What is considered a library load path is documented in the
# documentation for find_library_load_path.
#
# If the slug is not an absolute path it is considered a library name or
# relative path. load_safe attempts to find the library load path using
# find_in_bats_lib_path.
#
# If load_safe can find a library load path it is passed to _load.
# If _load fails load_safe returns 1.
#
# If no library load path can be found load_safe prints an error message
# and returns 1.
load_safe() {
  local slug="${1:?}" library_path

  # Check if slug is an absolute path
  if [[ "${slug:0:1}" == / ]]; then

    # Check for library load paths
    library_path="$(find_library_load_path "$slug")"
    if [[ -n "$library_path" ]]; then
      # A library load path was found, load it
      _load "$library_path"
      return $?
    fi

    # No library load path can be found
    printf "Absolute path '%s' does not point to a valid bats library\n" "$slug" >&2
    return 1
  fi

  # Check for library load paths in BATS_TEST_DIRNAME and BATS_LIB_PATH
  library_path="$(find_in_bats_lib_path "$slug")"
  if [[ -z "$library_path" ]]; then
    printf "Could not find library '%s' relative to test file or in BATS_LIB_PATH\n" "$slug" >&2
    return 1
  fi

  _load "$library_path"
  return $?
}

# load acts like load_safe but exits the shell instead of returning 1.
load() {
    if ! load_safe "$@"; then
        exit 1
    fi
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
