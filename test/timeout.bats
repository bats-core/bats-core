#!/usr/bin/env bats

load test_helper
fixtures bats

@test "test faster than timeout" {
    run bats -E 3 "$FIXTURE_ROOT/sleep2.bats"
}

@test "tests longer than timeout" {
    run bats -E 1 "$FIXTURE_ROOT/sleep2.bats"
    [ $status -ne 0 ]
}

