load test_helper
fixtures timeout

bats_require_minimum_version 1.5.0

@test "test faster than timeout" {
  SECONDS=0
  TIMEOUT=10
  reentrant_run -0 env BATS_TEST_TIMEOUT=$TIMEOUT SLEEP=1 bats -T "$FIXTURE_ROOT"
  [ "${lines[0]}" == '1..1' ]
  [[ "${lines[1]}" == 'ok 1 my sleep 1 in '*'ms' ]] || false
  [ "${#lines[@]}" -eq 2 ]
  # the timeout background process should not hold up execution
  ((SECONDS < TIMEOUT)) || false
}

@test "test longer than timeout" {
  SECONDS=0
  reentrant_run ! env BATS_TEST_TIMEOUT=1 SLEEP=10 bats -T "$FIXTURE_ROOT"
  [ "${lines[0]}" == '1..1' ]
  [[ "${lines[1]}" == 'not ok 1 my sleep 10 in '*'ms # timeout after 1s' ]] || false
  [ "${lines[2]}" == "# (in test file $RELATIVE_FIXTURE_ROOT/sleep2.bats, line 2)" ]
  [ "${lines[3]}" == "#   \`sleep \"\${SLEEP?}\"' failed due to timeout" ]
  ((SECONDS < 10)) || false
}

@test "sleep in run" {
    run sleep 10
}
