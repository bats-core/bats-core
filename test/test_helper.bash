emulate_bats_env() {
  export BATS_CWD="$PWD"
  export BATS_TEST_PATTERN="^[[:blank:]]*@test[[:blank:]]+(.*[^[:blank:]])[[:blank:]]+\{(.*)\$"
  export BATS_TEST_FILTER=
  export BATS_ROOT_PID=$$
  export BATS_RUN_TMPDIR=$(mktemp -d "${BATS_RUN_TMPDIR}/emulated-tmpdir-${BATS_ROOT_PID}-XXXXXX")
}

fixtures() {
  FIXTURE_ROOT="$BATS_TEST_DIRNAME/fixtures/$1"
  RELATIVE_FIXTURE_ROOT="${FIXTURE_ROOT#$BATS_CWD/}"
}

filter_control_sequences() {
  "$@" | sed $'s,\x1b\\[[0-9;]*[a-zA-Z],,g'
}

if ! command -v tput >/dev/null; then
  tput() {
    printf '1000\n'
  }
  export -f tput
fi

emit_debug_output() {
  printf '%s\n' 'output:' "$output" >&2
}
