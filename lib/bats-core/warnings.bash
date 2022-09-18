#!/usr/bin/env bash

# shellcheck source=lib/bats-core/tracing.bash
source "$BATS_ROOT/lib/bats-core/tracing.bash"

# generate a warning report for the parent call's call site
bats_generate_warning() { # <warning number> [--no-stacktrace] [<printf args for warning string>...]
  local warning_number="${1-}" padding="00"
  shift
  local no_stacktrace=
  if [[ ${1-} == --no-stacktrace ]]; then
    no_stacktrace=1
    shift
  fi
  if [[ $warning_number =~ [0-9]+ ]] && ((warning_number < ${#BATS_WARNING_SHORT_DESCS[@]})); then
    {
      printf "BW%s: ${BATS_WARNING_SHORT_DESCS[$warning_number]}\n" "${padding:${#warning_number}}${warning_number}" "$@"
      if [[ -z "$no_stacktrace" ]]; then
        bats_capture_stack_trace
        BATS_STACK_TRACE_PREFIX='      ' bats_print_stack_trace "${BATS_DEBUG_LAST_STACK_TRACE[@]}"
      fi
    } >>"$BATS_WARNING_FILE" 2>&3
  else
    printf "Invalid Bats warning number '%s'. It must be an integer between 1 and %d." "$warning_number" "$((${#BATS_WARNING_SHORT_DESCS[@]} - 1))" >&2
    exit 1
  fi
}

# generate a warning if the BATS_GUARANTEED_MINIMUM_VERSION is not high enough
bats_warn_minimum_guaranteed_version() { # <feature> <minimum required version>
  if bats_version_lt "$BATS_GUARANTEED_MINIMUM_VERSION" "$2"; then
    bats_generate_warning 2 "$1" "$2" "$2"
  fi
}

# put after functions to avoid line changes in tests when new ones get added
BATS_WARNING_SHORT_DESCS=(
  # to start with 1
  'PADDING'
  # see issue #578 for context
  "\`run\`'s command \`%s\` exited with code 127, indicating 'Command not found'. Use run's return code checks, e.g. \`run -127\`, to fix this message."
  "%s requires at least BATS_VERSION=%s. Use \`bats_require_minimum_version %s\` to fix this message."
  "\`setup_suite\` is visible to test file '%s', but was not executed. It belongs into 'setup_suite.bash' to be picked up automatically."
)
