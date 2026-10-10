# This file is loaded through BASH_ENV to inject a failure at an exact command
# boundary in another Bash process.
set -T

_bats_inject_fault() {
  local command=$1
  local running_job

  [[ ${0##*/} == "${BATS_FAULT_SCRIPT:-}" ]] || return 0
  # shellcheck disable=SC2053 # BATS_FAULT_COMMAND is intentionally a pattern.
  [[ $command == ${BATS_FAULT_COMMAND:-} ]] || return 0
  if [[ -n ${BATS_FAULT_REQUIRE_RUNNING_JOB:-} ]]; then
    running_job=$(jobs -pr)
    [[ -n $running_job ]] || return 0
  fi

  trap - DEBUG

  case ${BATS_FAULT_CAPTURE:-} in
  RUNNING_JOB)
    printf '%s\n' "$running_job" >"$BATS_FAULT_CAPTURE_FILE"
    ;;
  esac

  case ${BATS_FAULT_ACTION:-exit} in
  exit)
    exit "${BATS_FAULT_STATUS:-23}"
    ;;
  TERM-current-shell)
    # $BASHPID is the shell currently being debugged. A command substitution
    # forks a subshell that is already reaped before `kill` can use its PID.
    kill -TERM "$BASHPID"
    ;;
  esac
}

trap '_bats_inject_fault "$BASH_COMMAND"' DEBUG
