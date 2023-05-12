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

bats_pipe() { # [-N] [--] command0 [ \| command1 [ \| command2 [...]]]
  # This will run each command given, piping them appropriately.
  # Meant to be used in combination with `run` helper to allow piped commands
  # to be used.
  # Note that `\|` must be used, not `|`.
  # By default, the exit code of this command will be the last failure in the
  # chain of piped commands (similar to `set -o pipefail`).
  # Supplying -N (e.g. -0) will instead always use the exit code of the command
  # at that position in the chain.

  local pipefail_position=

  # parse options starting with -
  while [[ $# -gt 0 ]] && [[ $1 == -* ]]; do
    case "$1" in
    -[0-9]*)
      pipefail_position="${1#-}"
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

  # parse arguments and find pipes
  local commands_and_args=("$@")
  local pipe_positions=()
  local previous_pipe=-1
  for (( index = 0; index < $#; index++ )); do
    local current_command_or_arg="${commands_and_args[$index]}"
    if [ "$current_command_or_arg" = "|" ]; then
      if [ "$index" -eq 0 ]; then
        printf "Usage error: Cannot have leading \`\\|\`.\n" >&2
        return 1
      fi
      if [ "$(( previous_pipe + 1 ))" -ge "$index" ]; then
        printf "Usage error: Cannot have consecutive \`\\|\`. Found at argument position '%s'.\n" "$index" >&2
        return 1
      fi
      pipe_positions+=("$index")
      previous_pipe="$index"
    fi
  done

  if [ "$previous_pipe" -gt 0 ] && [ "$previous_pipe" -eq "$(( $# - 1 ))" ]; then
    printf "Usage error: Cannot have trailing \`\\|\`.\n" >&2
    return 1
  fi

  if [ "${#pipe_positions[@]}" -eq 0 ]; then
    # Don't allow for no pipes. This might be a typo in the test,
    # e.g. `run bats_pipe command0 | command1`
    # instead of `run bats_pipe command0 \| command1`
    # Unfortunately, we can't catch `run bats_pipe command0 \| command1 | command2`.
    # But this check is better than just allowing no pipes.
    printf "Usage error: No \`\\|\`s found. Is this an error?\n" >&2
    return 1
  fi

  if [ -n "$pipefail_position" ] && [ "$pipefail_position" -gt "${#pipe_positions[@]}" ]; then
    printf "Usage error: Too large of -N argument given. Argument value: '%s'.\n" "$pipefail_position" >&2
    return 1
  fi

  # we need to add on an extra "pipe position" so that the end can consistently
  # find its arg length.
  pipe_positions+=($#)

  # recursive base case to simply run a command with its args
  # runs a command at the given position with appropriate arguments
  run_command_at_position() {
    local given_position="$1"

    local command_position=
    if [ "$given_position" -eq 0 ]; then
      command_position=0
    else
      local associated_pipe="$(( given_position - 1 ))"
      local associated_pipe_position="${pipe_positions[$associated_pipe]}"
      command_position="$(( associated_pipe_position + 1 ))"
    fi
    local command_to_run="${commands_and_args[$command_position]}"

    local arguments_position="$(( command_position + 1 ))"
    local next_pipe_position="${pipe_positions[$given_position]}"
    local arg_count="$(( next_pipe_position - command_position - 1 ))"

    if [ "$arg_count" -eq 0 ]; then
      $command_to_run
    else
      local arguments=("${commands_and_args[@]:$arguments_position:$arg_count}")
      $command_to_run "${arguments[@]}"
    fi
  }

  # recursive func to handle piping
  # will run all commands before the given position, chaining piping.
  # Ex: if "3" is given, this will run `command0 | command1 | command2`.
  run_leading_commands_until_position() {
    local exclusive_position="$1"

    local result_status=
    if [ "$exclusive_position" -le 1 ]; then
      run_command_at_position 0
      result_status="$?"
    else
      local last_position_to_run="$(( exclusive_position - 1 ))"

      # recurse by calling earlier commands which will then be piped into the
      # (local) last command to run.
      run_leading_commands_until_position "$last_position_to_run" | run_command_at_position "$last_position_to_run"
      # note that we are immediately grabbing PIPESTATUS, and not grabbing $?
      # we can only grab one of the two, but we can get the equivalent of $?
      # from PIPESTATUS (see below).
      local pipe_status=("${PIPESTATUS[@]}")

      # check if we are to return the status code from an exact position, or
      # use "last fail" (like `set -o pipefail` would).
      if [ -n "$pipefail_position" ]; then
        # if the target pipefail is less than our "last_position_to_run", then
        # it is being propagated through the left-hand command.
        if [ "$pipefail_position" -lt "$last_position_to_run" ]; then
          result_status="${pipe_status[0]}"
        elif [ "$pipefail_position" -eq "$last_position_to_run" ]; then
          # if the target pipefail is equal to our "last_position_to_run", then
          # it is being returned through the right-hand command.
          result_status="${pipe_status[1]}"
        else
          # if the target pipefail is greater than our "last_position_to_run",
          # then it doesn't matter what we return, the recursive parent caller
          # will not use this value. Just return 0.
          result_status=0
        fi
      else
        # if we need to return the "last failure",
        # take the last pipe status, if it failed.
        if [ "${pipe_status[1]}" -ne 0 ]; then
          result_status="${pipe_status[1]}"
        else
          # if the last pipe status didn't fail,
          # take whatever the first pipe status is.
          result_status="${pipe_status[0]}"
        fi
      fi
    fi

    return "$result_status"
  }

  bats_pipe_recurse() {
    local relative_result_position="$1"
    shift
    # collect left hand side command of (first) pipe
    local first_command=()
    while (( $# > 0 )) && [[ "$1" != '|' ]]; do
      first_command+=("$1")
      shift
    done

    local result_status=
    # if there is at least 1 remaining pipe, we need to call recursively.
    if (( $# > 0 )); then
      # consume pipe symbol '|', (originally passed as '\|')
      # this leaves only the recursive parameters to be called.
      shift
      "${first_command[@]}" | bats_pipe_recurse "$(( relative_result_position - 1 ))" "$@"
      # note that we are immediately grabbing PIPESTATUS, and not grabbing $?.
      # we can only grab one of the two, but we can get the equivalent of $?
      # from PIPESTATUS (see below).
      local pipe_status=("${PIPESTATUS[@]}")

      if [[ "$relative_result_position" -eq 0 ]]; then
        # If this is the targeted position, return the result of the first command run.
        result_status="${pipe_status[0]}"
      elif [[ "$relative_result_position" -gt 0 ]]; then
        # If the targeted position isn't reached yet, return the result of the recursive call.
        # The targeted position's result will come from there.
        result_status="${pipe_status[1]}"
      else
        # If the received target position is negative, one of the following is true:
        # the target is already passed in a shallower recursive call
        # or we are performing default "last failure" behavior.

        # in the former case, it doesn't matter what we return.
        # so just do the "last failure" logic.

        # if we need to return the "last failure",
        # take the last pipe status, if it failed.
        if [ "${pipe_status[1]}" -ne 0 ]; then
          result_status="${pipe_status[1]}"
        else
          # if the last pipe status didn't fail,
          # take whatever the first pipe status is.
          result_status="${pipe_status[0]}"
        fi
      fi
    else
      # no more pipes -> execute command
      "${first_command[@]}"
      result_status="$?"
    fi

    return "$result_status"
  }

  bats_pipe_eval() {
    local pipefail_position="$1"
    shift

    eval "$@" '; __bats_pipe_eval_pipe_status=(${PIPESTATUS[@]})'

    local result_status=
    if (( $pipefail_position < 0 )); then
      # if we are performing default "last failure" behavior,
      # iterate backwards through pipe_status to find the last error.
      result_status=0
      for index in "${!__bats_pipe_eval_pipe_status[@]}"; do
        local negative_index="-$((index + 1))"
        local status_at_negative_index="${__bats_pipe_eval_pipe_status[$negative_index]}"
        if (( status_at_negative_index != 0 )); then
          result_status="$status_at_negative_index"
          break;
        fi
      done
    else
      result_status="${__bats_pipe_eval_pipe_status[$pipefail_position]}"
    fi

    return "$result_status"
  }

  # run commands and handle appropriate piping
  local result_status=

  # no need to call `set -o pipefail` here (which also means we don't have to
  # worry about setting it back).
  # note that `pipefail_position` will be referenced in
  # `run_leading_commands_until_position` for selecting the correct status code
  # to propagate (which simulates `set -o pipefail`, see related comment
  # there).
  #run_leading_commands_until_position "${#pipe_positions[@]}"
  #result_status="$?"

  # # call recurse with full set of arguemnts.
  # # note: if $pipefail_position was not given, we want to do "last failure" logic (done with negative values).
  # bats_pipe_recurse "${pipefail_position:--1}" "$@"
  # result_status="$?"

  bats_pipe_eval "${pipefail_position:--1}" "$@"
  result_status="$?"

  return "$result_status"
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
