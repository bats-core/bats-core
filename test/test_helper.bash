fixtures() {
  FIXTURE_ROOT="$BATS_TEST_DIRNAME/fixtures/$1"
  bats_trim_filename "$FIXTURE_ROOT" 'RELATIVE_FIXTURE_ROOT'
}

make_bats_test_suite_tmpdir() {
  export BATS_TEST_SUITE_TMPDIR="$BATS_TMPDIR/bats-test-tmp"
  mkdir -p "$BATS_TEST_SUITE_TMPDIR"
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

teardown() {
  if [[ -n "$BATS_TEST_SUITE_TMPDIR" ]]; then
    rm -rf "$BATS_TEST_SUITE_TMPDIR"
  fi
}
