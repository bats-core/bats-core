# Simulate a `wait` whose status Bash has discarded because its PID was reused.
wait() {
  if [[ ${FUNCNAME[1]} == bats_forward_output_of_parallel_test ]]; then
    builtin wait "$@"
    printf 'wait: pid %s is not a child of this shell\n' "$1" >&2
    return 127
  fi
  builtin wait "$@"
}
