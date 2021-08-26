load test_helper
fixtures timeout

@test "test faster than timeout" {
    run bats -E 3 "$FIXTURE_ROOT"
}

@test "test longer than timeout" {
    run bats -E 1 "$FIXTURE_ROOT"
    [ $status -ne 0 ]
}

