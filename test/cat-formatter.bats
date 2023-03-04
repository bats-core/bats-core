load 'test_helper'
fixtures bats # reuse bats fixtures

@test "passing test" {
  reentrant_run bats --formatter cat "${FIXTURE_ROOT}/passing.bats"

  echo ${BATS_TEST_FILENAME}

  [ "${lines[0]}" == '1..1' ]
  [ "${lines[1]}" == "suite ${FIXTURE_ROOT}/passing.bats" ]
  [ "${lines[2]}" == 'begin 1 a passing test' ]
  [ "${lines[3]}" == 'ok 1 a passing test' ]
  [ "${#lines[@]}" -eq 4 ]
}

@test "failing test" {
  reentrant_run bats --formatter cat "${FIXTURE_ROOT}/failing.bats"

  [ "${lines[0]}" == '1..1' ]
  [ "${lines[1]}" == "suite ${FIXTURE_ROOT}/failing.bats" ]
  [ "${lines[2]}" == 'begin 1 a failing test' ]
  [ "${lines[3]}" == 'not ok 1 a failing test' ]
  [ "${lines[4]}" == "# (in test file ${RELATIVE_FIXTURE_ROOT}/failing.bats, line 4)" ]
  [ "${lines[5]}" == "#   \`eval \"( exit \${STATUS:-1} )\"' failed" ]
  [ "${#lines[@]}" -eq 6 ]
}

@test "passing test with timing" {
  reentrant_run bats --formatter cat --timing "${FIXTURE_ROOT}/passing.bats"

  [ "${lines[0]}" == '1..1' ]
  [ "${lines[1]}" == "suite ${FIXTURE_ROOT}/passing.bats" ]
  [ "${lines[2]}" == 'begin 1 a passing test' ]
  [ "${lines[3]::23}" == 'ok 1 a passing test in ' ]
  [ "${lines[3]: -2}" == 'ms' ]
  [ "${#lines[@]}" -eq 4 ]
}

@test "failing test with timing" {
  reentrant_run bats --formatter cat --timing "${FIXTURE_ROOT}/failing.bats"

  [ "${lines[0]}" == '1..1' ]
  [ "${lines[1]}" == "suite ${FIXTURE_ROOT}/failing.bats" ]
  [ "${lines[2]}" == 'begin 1 a failing test' ]
  [ "${lines[3]::27}" == 'not ok 1 a failing test in ' ]
  [ "${lines[3]: -2}" == 'ms' ]
  [ "${lines[4]}" == "# (in test file ${RELATIVE_FIXTURE_ROOT}/failing.bats, line 4)" ]
  [ "${lines[5]}" == "#   \`eval \"( exit \${STATUS:-1} )\"' failed" ]
  [ "${#lines[@]}" -eq 6 ]
}
