#!/usr/bin/env bash

BATS_TEST_DIRNAME="${BATS_TEST_FILENAME%/*}"
BATS_TEST_NAMES=()

# shellcheck source=lib/bats-core/warnings.bash
source "$BATS_ROOT/lib/bats-core/warnings.bash"

# find_in_bats_lib_path echoes the first recognized load path to
# a library in BATS_LIB_PATH or relative to BATS_TEST_DIRNAME.
#
# Libraries relative to BATS_TEST_DIRNAME take precedence over
# BATS_LIB_PATH.
#
# Library load paths are recognized using find_library_load_path.
#
# If no library is found find_in_bats_lib_path returns 1.
find_in_bats_lib_path() { # <return-var> <library-name>
  local return_var="${1:?}"
  local library_name="${2:?}"

  local -a bats_lib_paths
  IFS=: read -ra bats_lib_paths <<<"$BATS_LIB_PATH"

  for path in "${bats_lib_paths[@]}"; do
    if [[ -f "$path/$library_name" ]]; then
      printf -v "$return_var" "%s" "$path/$library_name"
      # A library load path was found, return
      return 0
    elif [[ -f "$path/$library_name/load.bash" ]]; then
      printf -v "$return_var" "%s" "$path/$library_name/load.bash"
      # A library load path was found, return
      return 0
    fi
  done

  return 1
}

# bats_internal_load expects an absolute path that is a library load path.
#
# If the library load path points to a file (a library loader) it is
# sourced.
#
# If it points to a directory all files ending in .bash inside of the
# directory are sourced.
#
# If the sourcing of the library loader or of a file in a library
# directory fails bats_internal_load prints an error message and returns 1.
#
# If the passed library load path is not absolute or is not a valid file
# or directory bats_internal_load prints an error message and returns 1.
bats_internal_load() {
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
    return 0
  fi

  printf "Passed library load path is neither a library loader nor library directory: %s\n" "$library_load_path" >&2
  return 1
}

# bats_load_safe accepts an argument called 'slug' and attempts to find and
# source a library based on the slug.
#
# A slug can be an absolute path, a library name or a relative path.
#
# If the slug is an absolute path bats_load_safe attempts to find the library
# load path using find_library_load_path.
# What is considered a library load path is documented in the
# documentation for find_library_load_path.
#
# If the slug is not an absolute path it is considered a library name or
# relative path. bats_load_safe attempts to find the library load path using
# find_in_bats_lib_path.
#
# If bats_load_safe can find a library load path it is passed to bats_internal_load.
# If bats_internal_load fails bats_load_safe returns 1.
#
# If no library load path can be found bats_load_safe prints an error message
# and returns 1.
bats_load_safe() {
  local slug="${1:?}"
  if [[ ${slug:0:1} != / ]]; then # relative paths are relative to BATS_TEST_DIRNAME
    slug="$BATS_TEST_DIRNAME/$slug"
  fi

  if [[ -f "$slug.bash" ]]; then
    bats_internal_load "$slug.bash"
    return $?
  elif [[ -f "$slug" ]]; then
    bats_internal_load "$slug"
    return $?
  fi

  # loading from PATH (retained for backwards compatibility)
  if [[ ! -f "$1" ]] && type -P "$1" >/dev/null; then
    # shellcheck disable=SC1090
    source "$1"
    return $?
  fi

  # No library load path can be found
  printf "bats_load_safe: Could not find '%s'[.bash]\n" "$slug" >&2
  return 1
}

bats_load_library_safe() { # <slug>
  local slug="${1:?}" library_path

  # Check for library load paths in BATS_TEST_DIRNAME and BATS_LIB_PATH
  if [[ ${slug:0:1} != / ]]; then
    if ! find_in_bats_lib_path library_path "$slug"; then
      printf "Could not find library '%s' relative to test file or in BATS_LIB_PATH\n" "$slug" >&2
      return 1
    fi
  else
    # absolute paths are taken as is
    library_path="$slug"
    if [[ ! -f "$library_path" ]]; then
      printf "Could not find library on absolute path '%s'\n" "$library_path" >&2
      return 1
    fi
  fi

  bats_internal_load "$library_path"
  return $?
}

# immediately exit on error, use bats_load_library_safe to catch and handle errors
bats_load_library() { # <slug>
  if ! bats_load_library_safe "$@"; then
    exit 1
  fi
}

# load acts like bats_load_safe but exits the shell instead of returning 1.
load() {
  if ! bats_load_safe "$@"; then
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
  local -r output_array_name="$1"
  local -r input_var_name="$2"
  local input="${!input_var_name}"
  if [[ $keep_empty_lines ]]; then
    local bats_separate_lines_lines=()
    if [[ -n "$input" ]]; then # avoid getting an empty line for empty input
      # remove one trailing \n if it exists to compensate its addition by <<<
      input=${input%$'\n'}
      while IFS= read -r line; do
        bats_separate_lines_lines+=("$line")
      done <<<"${input}"
    fi
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
  local has_flags=
  # parse options starting with -
  while [[ $# -gt 0 ]] && [[ $1 == -* || $1 == '!' ]]; do
    has_flags=1
    case "$1" in
    '!')
      expected_rc=-1
      ;;
    -[0-9]*)
      expected_rc=${1#-}
      if [[ $expected_rc =~ [^0-9] ]]; then
        printf "Usage error: run: '-NNN' requires numeric NNN (got: %s)\n" "$expected_rc" >&2
        return 1
      elif [[ $expected_rc -gt 255 ]]; then
        printf "Usage error: run: '-NNN': NNN must be <= 255 (got: %d)\n" "$expected_rc" >&2
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

  if [[ -n $has_flags ]]; then
    bats_warn_minimum_guaranteed_version "Using flags on \`run\`" 1.5.0
  fi

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
  if [[ $keep_empty_lines ]]; then
    # 'output', 'status', 'lines' are global variables available to tests.
    # preserve trailing newlines by appending . and removing it later
    # shellcheck disable=SC2034
    output="$(
      "$pre_command" "$@"
      status=$?
      printf .
      exit $status
    )" && status=0 || status=$?
    output="${output%.}"
  else
    # 'output', 'status', 'lines' are global variables available to tests.
    # shellcheck disable=SC2034
    output="$("$pre_command" "$@")" && status=0 || status=$?
  fi

  bats_separate_lines lines output

  if [[ "$output_case" == separate ]]; then
    # shellcheck disable=SC2034
    read -d '' -r stderr <"$bats_run_separate_stderr_file" || true
    bats_separate_lines stderr_lines stderr
  fi

  # shellcheck disable=SC2034
  BATS_RUN_COMMAND="${*}"
  set "-$origFlags"

  bats_run_print_output() {
    if [[ -n "$output" ]]; then
      printf "%s\n" "$output"
    fi
    if [[ "$output_case" == separate && -n "$stderr" ]]; then
      printf "stderr:\n%s\n" "$stderr"
    fi
  }

  if [[ -n "$expected_rc" ]]; then
    if [[ "$expected_rc" = "-1" ]]; then
      if [[ "$status" -eq 0 ]]; then
        BATS_ERROR_SUFFIX=", expected nonzero exit code!"
        bats_run_print_output
        return 1
      fi
    elif [ "$status" -ne "$expected_rc" ]; then
      # shellcheck disable=SC2034
      BATS_ERROR_SUFFIX=", expected exit code $expected_rc, got $status"
      bats_run_print_output
      return 1
    fi
  elif [[ "$status" -eq 127 ]]; then # "command not found"
    bats_generate_warning 1 "$BATS_RUN_COMMAND"
  fi

  if [[ ${BATS_VERBOSE_RUN:-} ]]; then
    bats_run_print_output
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
    printf 'begin %d %s\n' "$BATS_SUITE_TEST_NUMBER" "${BATS_TEST_NAME_PREFIX:-}$BATS_TEST_DESCRIPTION" >&3
  fi
  setup
}

bats_test_function() {
  local tags=()
  if [[ "$1" == --tags ]]; then
    IFS=',' read -ra tags <<<"$2"
    shift 2
  fi
  local test_name="$1"
  BATS_TEST_NAMES+=("$test_name")
  if [[ "$test_name" == "$BATS_TEST_NAME" ]]; then
    # shellcheck disable=SC2034
    BATS_TEST_TAGS=("${tags[@]+${tags[@]}}")
  fi
}

# decides whether a failed test should be run again
bats_should_retry_test() {
  # test try number starts at 1
  # 0 retries means run only first try
  ((BATS_TEST_TRY_NUMBER <= BATS_TEST_RETRIES))
}
