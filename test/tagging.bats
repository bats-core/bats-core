#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load test_helper
    fixtures tagging
}

@test "No tag filter runs all tests" {
    run -0 bats "$FIXTURE_ROOT/tagged.bats"
    [ "${lines[0]}" == "1..5" ]
    [ "${lines[1]}" == "ok 1 No tags" ]
    [ "${lines[2]}" == "ok 2 Only file tags" ]
    [ "${lines[3]}" == "ok 3 File and test tags" ]
    [ "${lines[4]}" == "ok 4 File and other test tags" ]
    [ "${lines[5]}" == "ok 5 Only test tags" ]
    [ ${#lines[@]} -eq 6 ]
}
