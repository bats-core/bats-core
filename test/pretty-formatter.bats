#!/usr/bin/env bats

setup() {
  load test_helper
  fixtures bats
}

@test "Timing printout shows milliseconds" {
    format_example_stream() {
        bats-format-pretty -T  <<HERE
1..1
suite /test/path
begin 1 test
ok 1 test in 123ms
HERE
    }
    run format_example_stream
    echo "$output"
    [[ "${lines[1]}" == *'[123]'* ]]
}

@test "pretty formatter summary is colorized red on failure" {
  bats_require_minimum_version 1.5.0
  run -1 bats --pretty "$FIXTURE_ROOT/failing.bats"
  
  [ "${lines[4]}" == $'\033[0m\033[31;1m' ] # TODO: avoid checking for the leading reset too
  [ "${lines[5]}" == '1 test, 1 failure' ]
  [ "${lines[6]}" == $'\033[0m' ]
}

@test "pretty formatter summary is colorized green on success" {
  bats_require_minimum_version 1.5.0
  run -0 bats --pretty "$FIXTURE_ROOT/passing.bats"

  [ "${lines[2]}" == $'\033[0m\033[32;1m' ] # TODO: avoid checking for the leading reset too
  [ "${lines[3]}" == '1 test, 0 failures' ]
  [ "${lines[4]}" == $'\033[0m' ]
}