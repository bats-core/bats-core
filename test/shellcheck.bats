#!/usr/bin/env bats

load test_helper
fixtures shellcheck

setup() {
    if ! command -v shellcheck; then
        skip 'This test requires shellcheck to be installed'
    fi
}

@test "shellcheck does not choke on custom syntax" {
    run bats --shellcheck "${FIXTURE_ROOT}/valid.bats"
    echo "$output"
    [[ $status -eq 0 ]]
    [[ -z "$output" ]]
}

@test "shellcheck errors are mapped to the correct file" {
    run bats --shellcheck "${FIXTURE_ROOT}/failure.bats"
    echo "$output"
    [[ $status -ne 0 ]]
    [[ "${lines[0]}" == "In ${RELATIVE_FIXTURE_ROOT}/failure.bats line 2:" ]]
}