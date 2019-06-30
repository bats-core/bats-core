emulate_bats_env() {
  export BATS_CWD="$PWD"
  export BATS_TEST_PATTERN="^[[:blank:]]*@test[[:blank:]]+(.*[^[:blank:]])[[:blank:]]+\{(.*)\$"
  export BATS_TEST_FILTER=
}

fixtures() {
  FIXTURE_ROOT="$BATS_TEST_DIRNAME/fixtures/$1"
  RELATIVE_FIXTURE_ROOT="${FIXTURE_ROOT#$BATS_CWD/}"
}

make_bats_test_suite_tmpdir() {
  export BATS_TEST_SUITE_TMPDIR="$BATS_TMPDIR/bats-test-tmp"
  mkdir -p "$BATS_TEST_SUITE_TMPDIR"
}

arrays_equal() {
  [ "$#" -ge 2 ] || return 0

  # Simple pair-wise comparison.
  if [ "$#" -eq 2 ]
  then
    # An eval-based version of "declare -n" which works on old Bash versions.
    fmt='%s=( "${%s[@]}" )'
    eval "$(printf "$fmt" "left"  "$1")"
    eval "$(printf "$fmt" "right" "$2")"

    # Must be same length.
    [ "${#left[@]}" -eq "${#right[@]}" ] || return 1
    # Each element must be equal.
    for (( i = 0; i < "${#left[@]}"; i++ ))
    do
      [[ "${left[$i]}" == "${right[$i]}" ]] || return 1
    done

    # They must be equal.
    return 0
  fi

  # If there are more than two arguments, we have to compare them pair-wise. So
  # we take the input list of things to compare, and rotate it by one and then
  # do pair-wise comparisons that way.
  local lvars=( "$@" )
  local rvars=( "${@:2}" "$1" )
  for (( i = 0; i < "$#"; i++ ))
  do
    eval arrays_equal "${lvars[$i]}" "${rvars[$i]}" || return 1
  done
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
