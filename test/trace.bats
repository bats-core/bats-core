#!/usr/bin/env bats

setup() {
    load test_helper
    fixtures trace
}

@test "no --trace doesn't show anything on failure" {
  run '=1' bats "$FIXTURE_ROOT/failing_complex.bats"
  [ "${lines[0]}" = "1..1" ]
  [ "${lines[1]}" = "not ok 1 a complex failing test" ]
  [ "${lines[2]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/failing_complex.bats, line 4)" ]
  [ "${lines[3]}" = "#   \`[ \$status -eq 0 ]' failed" ]
  [ "${lines[4]}" = "# 123" ]
  [ ${#lines[@]} -eq 5 ]
}

@test "--trace prints trace" {
  run '=1' bats --trace "$FIXTURE_ROOT/failing_complex.bats"
  [ "${lines[0]}" = '1..1' ]
  [ "${lines[1]}" = 'not ok 1 a complex failing test' ]
  [ "${lines[2]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/failing_complex.bats, line 4)" ]
  [ "${lines[3]}" = "#   \`[ \$status -eq 0 ]' failed" ]
  [ "${lines[4]}" = '# $ [failing_complex.bats:2]' ]
  [ "${lines[5]}" = '# $ echo 123' ]
  [ "${lines[6]}" = '# 123' ]
  [ "${lines[7]}" = '# $ [failing_complex.bats:3]' ]
  # shellcheck disable=SC2016
  [ "${lines[8]}" = '# $ run bats "$BATS_TEST_DIRNAME/failing.bats"' ]
  [ "${lines[9]}" = '# $ [failing_complex.bats:4]' ]
  # shellcheck disable=SC2016
  [ "${lines[10]}" = '# $ [ $status -eq 0 ]' ]
  [ ${#lines[@]} -eq 11 ]
}

@test "--trace recurses into functions but not into run" {
    run '=1' bats --trace "$FIXTURE_ROOT/failing_recursive.bats"
    echo "$output"
    [ "${lines[0]}" = '1..1' ]
    [ "${lines[1]}" = 'not ok 1 a recursive failing test' ]
    [ "${lines[2]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/failing_recursive.bats, line 12)" ]
    [ "${lines[3]}" = "#   \`false' failed" ]
    [ "${lines[4]}" = '# $ [failing_recursive.bats:9]' ]
    [ "${lines[5]}" = '# $ echo Outer' ]
    [ "${lines[6]}" = '# Outer' ]
    [ "${lines[7]}" = '# $ [failing_recursive.bats:10]' ]
    [ "${lines[8]}" = '# $ fun 2' ]
    [ "${lines[9]}" = '# $$ [failing_recursive.bats:2]' ]
    # shellcheck disable=SC2016
    [ "${lines[10]}" = '# $$ echo "$1"' ]
    [ "${lines[11]}" = '# 2' ]
    [ "${lines[12]}" = '# $$ [failing_recursive.bats:3]' ]
    # shellcheck disable=SC2016
    [ "${lines[13]}" = '# $$ [[ $1 -gt 0 ]]' ]
    [ "${lines[14]}" = '# $$ [failing_recursive.bats:4]' ]
    # shellcheck disable=SC2016
    [ "${lines[15]}" = '# $$ fun $(($1 - 1))' ]
    [ "${lines[16]}" = '# $$$ [failing_recursive.bats:2]' ]
    # shellcheck disable=SC2016
    [ "${lines[17]}" = '# $$$ echo "$1"' ]
    [ "${lines[18]}" = '# 1' ]
    [ "${lines[19]}" = '# $$$ [failing_recursive.bats:3]' ]
    # shellcheck disable=SC2016
    [ "${lines[20]}" = '# $$$ [[ $1 -gt 0 ]]' ]
    [ "${lines[21]}" = '# $$$ [failing_recursive.bats:4]' ]
    # shellcheck disable=SC2016
    [ "${lines[22]}" = '# $$$ fun $(($1 - 1))' ]
    [ "${lines[23]}" = '# $$$$ [failing_recursive.bats:2]' ]
    # shellcheck disable=SC2016
    [ "${lines[24]}" = '# $$$$ echo "$1"' ]
    [ "${lines[25]}" = '# 0' ]
    [ "${lines[26]}" = '# $$$$ [failing_recursive.bats:3]' ]
    # shellcheck disable=SC2016
    [ "${lines[27]}" = '# $$$$ [[ $1 -gt 0 ]]' ]
    [ "${lines[28]}" = '# $ [failing_recursive.bats:11]' ]
    [ "${lines[29]}" = '# $ run fun 2' ]
    [ "${lines[30]}" = '# $ [failing_recursive.bats:12]' ]
    [ "${lines[31]}" = '# $ false' ]
    [ ${#lines[@]} -eq 32 ]
}