#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
setup() {
  load test_helper
  fixtures trace
}

@test "no --trace doesn't show anything on failure" {
  reentrant_run -1 bats "$FIXTURE_ROOT/failing_complex.bats"
  [ "${lines[0]}" = "1..1" ]
  [ "${lines[1]}" = "not ok 1 a complex failing test" ]
  [ "${lines[2]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/failing_complex.bats, line 4)" ]
  [ "${lines[3]}" = "#   \`[ \$status -eq 0 ]' failed" ]
  [ "${lines[4]}" = "# 123" ]
  [ ${#lines[@]} -eq 5 ]
}

@test "--trace recurses into functions but not into run" {
  reentrant_run -1 bats --trace "$FIXTURE_ROOT/failing_recursive.bats" --line-reference-format colon

  [ "${lines[0]}" = '1..1' ]
  [ "${lines[1]}" = 'not ok 1 a recursive failing test' ]
  [ "${lines[2]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/failing_recursive.bats:12)" ]
  [ "${lines[3]}" = "#   \`false' failed" ]
  [ "${lines[4]}" = '# $ [failing_recursive.bats:9]' ]
  [ "${lines[5]}" = '# $ echo Outer' ]
  [ "${lines[6]}" = '# Outer' ]
  [ "${lines[7]}" = '# $ fun 2' ]
  [ "${lines[8]}" = '# $$ [failing_recursive.bats:2]' ]
  # shellcheck disable=SC2016
  [ "${lines[9]}" = '# $$ echo "$1"' ]
  [ "${lines[10]}" = '# 2' ]
  # shellcheck disable=SC2016
  [ "${lines[11]}" = '# $$ [[ $1 -gt 0 ]]' ]
  # shellcheck disable=SC2016
  [ "${lines[12]}" = '# $$ fun $(($1 - 1))' ]
  [ "${lines[13]}" = '# $$$ [failing_recursive.bats:2]' ]
  # shellcheck disable=SC2016
  [ "${lines[14]}" = '# $$$ echo "$1"' ]
  [ "${lines[15]}" = '# 1' ]
  # shellcheck disable=SC2016
  [ "${lines[16]}" = '# $$$ [[ $1 -gt 0 ]]' ]
  # shellcheck disable=SC2016
  [ "${lines[17]}" = '# $$$ fun $(($1 - 1))' ]
  [ "${lines[18]}" = '# $$$$ [failing_recursive.bats:2]' ]
  # shellcheck disable=SC2016
  [ "${lines[19]}" = '# $$$$ echo "$1"' ]
  [ "${lines[20]}" = '# 0' ]
  # shellcheck disable=SC2016
  [ "${lines[21]}" = '# $$$$ [[ $1 -gt 0 ]]' ]
  [ "${lines[22]}" = '# $ [failing_recursive.bats:11]' ]
  [ "${lines[23]}" = '# $ run fun 2' ]
  [ "${lines[24]}" = '# $ false' ]

  # the trace on return from a function differs between bash versions
  check_bash_5() {
    [ ${#lines[@]} -eq 25 ]
  }

  # "alias" same behavior to have single point of truth
  check_bash_4_4() { check_bash_5; }
  check_bash_4_3() { check_bash_5; }
  check_bash_4_2() { check_bash_4_0; }
  check_bash_4_1() { check_bash_4_0; }

  check_bash_4_0() {
    # bash bug: the lineno from the debug_trap spills over -> ignore it
    [ "${lines[25]}" = '# $ false' ]
    [ ${#lines[@]} -eq 26 ]
  }

  check_bash_3_2() {
    # lineno from function definition
    [ "${lines[25]}" = '# $ false' ]
    [ ${#lines[@]} -eq 26 ]
  }

  IFS=. read -r -a bash_version <<<"${BASH_VERSION}"
  check_func="check_bash_${bash_version[0]}"
  if [[ $(type -t "$check_func") != function ]]; then
    check_func="check_bash_${bash_version[0]}_${bash_version[1]}"
  fi
  $check_func
}
