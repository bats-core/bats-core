load 'test_helper'
fixtures bats # reuse bats fixtures

@test "passing test" {
  reentrant_run bats --formatter tap13 "${FIXTURE_ROOT}/passing.bats"

  [ "${lines[0]}" == 'TAP version 13' ]
  [ "${lines[1]}" == '1..1' ]
  [ "${lines[2]}" == 'ok 1 a passing test' ]
  [ "${#lines[@]}" -eq 3 ]
}

@test "failing test" {
  reentrant_run bats --formatter tap13 "${FIXTURE_ROOT}/failing.bats"

  [ "${lines[0]}" == 'TAP version 13' ]
  [ "${lines[1]}" == '1..1' ]
  [ "${lines[2]}" == 'not ok 1 a failing test' ]
  [ "${lines[3]}" == '  ---' ]
  [ "${lines[4]}" == '  message: |' ]
  [ "${lines[5]}" == "    (in test file ${RELATIVE_FIXTURE_ROOT}/failing.bats, line 4)" ]
  [ "${lines[6]}" == "      \`eval \"( exit \${STATUS:-1} )\"' failed" ]
  [ "${lines[7]}" == '  ...' ]
  [ "${#lines[@]}" -eq 8 ]
}

@test "passing test with timing" {
  reentrant_run bats --formatter tap13 --timing "${FIXTURE_ROOT}/passing.bats"

  [ "${lines[0]}" == 'TAP version 13' ]
  [ "${lines[1]}" == '1..1' ]
  [ "${lines[2]}" == 'ok 1 a passing test' ]
  [ "${lines[3]}" == '  ---' ]
  [ "${lines[4]::15}" == '  duration_ms: ' ]
  [ "${lines[5]}" == '  ...' ]

  [ "${#lines[@]}" -eq 6 ]
}

@test "failing test with timing" {
  reentrant_run bats --formatter tap13 --timing "${FIXTURE_ROOT}/failing.bats"

  [ "${lines[0]}" == 'TAP version 13' ]
  [ "${lines[1]}" == '1..1' ]
  [ "${lines[2]}" == 'not ok 1 a failing test' ]
  [ "${lines[3]}" == '  ---' ]
  [ "${lines[4]::15}" == '  duration_ms: ' ]
  [ "${lines[5]}" == '  message: |' ]
  [ "${lines[6]}" == "    (in test file ${RELATIVE_FIXTURE_ROOT}/failing.bats, line 4)" ]
  [ "${lines[7]}" == "      \`eval \"( exit \${STATUS:-1} )\"' failed" ]
  [ "${lines[8]}" == '  ...' ]
  [ "${#lines[@]}" -eq 9 ]
}
