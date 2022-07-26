load test_helper
fixtures timeout

bats_require_minimum_version 1.5.0

@test "test faster than timeout" {
    SECONDS=0
    run -0 env BATS_TEST_TIMEOUT=5 SLEEP=1 bats  "$FIXTURE_ROOT"
    [ "${lines[0]}" == '1..1' ]
    [ "${lines[1]}" == 'ok 1 my sleep 1' ]
    [ "${#lines[@]}" -eq 2 ]
    # the timeout background process should not hold up execution
    (( SECONDS < 5 )) || false
}

@test "test longer than timeout" {
    run ! env BATS_TEST_TIMEOUT=1 SLEEP=10 bats "$FIXTURE_ROOT"
    [ "${lines[0]}" == '1..1' ]
    [ "${lines[1]}" == 'not ok 1 my sleep 10 # timeout after 1s' ]
    [ "${lines[2]}" == '# (in test file test/fixtures/timeout/sleep2.bats, line 3)' ]
    [ "${lines[3]}" == "#   \`sleep \${SLEEP:-2}' failed due to timeout" ]
    [ "${lines[4]}" == "# Terminated" ]
    [ "${#lines[@]}" -eq 5 ]
}

@test "pretty fomatter timeout" {
    unset BATS_TIMING
    run ! env BATS_TEST_TIMEOUT=1 SLEEP=10 bats --pretty "$FIXTURE_ROOT"
    run filter_control_sequences echo "$output"
    [[ "${lines[1]}" == *'✗ my sleep 10' ]] || false
}

@test "pretty fomatter timeout plus timing info" {
    run ! env BATS_TEST_TIMEOUT=1 SLEEP=10 bats --pretty -T "$FIXTURE_ROOT"
    run filter_control_sequences echo "$output"
    [[ "${lines[1]}" == *'✗ my sleep 10 ['*']' ]] || false
}