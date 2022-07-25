load test_helper
fixtures timeout

bats_require_minimum_version 1.5.0

@test "test faster than timeout" {
    run -0 env BATS_TIMEOUT=3 bats  "$FIXTURE_ROOT"
    [ "${lines[0]}" == '1..1' ]
    [ "${lines[1]}" == 'ok 1 my sleep 2' ]
    [ "${#lines[@]}" -eq 2 ]
}

@test "test longer than timeout" {
    run ! env BATS_TIMEOUT=1 bats "$FIXTURE_ROOT"
    [ "${lines[0]}" == '1..1' ]
    [ "${lines[1]}" == 'not ok 1 my sleep 2 # timeout after 1s' ]
    [ "${lines[2]}" == '# (in test file test/fixtures/timeout/sleep2.bats, line 3)' ]
    [ "${lines[3]}" == "#   \`sleep 2' failed with status 141" ]
    [ "${#lines[@]}" -eq 4 ]
}

