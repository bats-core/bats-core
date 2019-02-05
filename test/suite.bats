#!/usr/bin/env bats

load test_helper
fixtures suite

@test "running a suite with no test files" {
  run bats "$FIXTURE_ROOT/empty"
  [ $status -eq 0 ]
  [ "$output" = "1..0" ]
}

@test "running a suite with one test file" {
  run bats "$FIXTURE_ROOT/single"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..1" ]
  [ "${lines[1]}" = "ok 1 a passing test" ]
}

@test "counting tests in a suite" {
  run bats -c "$FIXTURE_ROOT/single"
  [ $status -eq 0 ]
  [ "$output" -eq 1 ]

  run bats -c "$FIXTURE_ROOT/multiple"
  [ $status -eq 0 ]
  [ "$output" -eq 3 ]
}

@test "aggregated output of multiple tests in a suite" {
  run bats "$FIXTURE_ROOT/multiple"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..3" ]
  echo "$output" | grep "^ok . truth"
  echo "$output" | grep "^ok . more truth"
  echo "$output" | grep "^ok . quasi-truth"
}

@test "a failing test in a suite results in an error exit code" {
  FLUNK=1 run bats "$FIXTURE_ROOT/multiple"
  [ $status -eq 1 ]
  [ "${lines[0]}" = "1..3" ]
  echo "$output" | grep "^not ok . quasi-truth"
}

@test "running an ad-hoc suite by specifying multiple test files" {
  run bats "$FIXTURE_ROOT/multiple/a.bats" "$FIXTURE_ROOT/multiple/b.bats"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..3" ]
  echo "$output" | grep "^ok . truth"
  echo "$output" | grep "^ok . more truth"
  echo "$output" | grep "^ok . quasi-truth"
}

@test "extended syntax in suite" {
  emulate_bats_env
  FLUNK=1 run bats-exec-suite -x "$FIXTURE_ROOT/multiple/"*.bats
  [ $status -eq 1 ]
  [ "${lines[0]}" = "1..3" ]
  [ "${lines[1]}" = "begin 1 truth" ]
  [ "${lines[2]}" = "ok 1 truth" ]
  [ "${lines[3]}" = "begin 2 more truth" ]
  [ "${lines[4]}" = "ok 2 more truth" ]
  [ "${lines[5]}" = "begin 3 quasi-truth" ]
  [ "${lines[6]}" = "not ok 3 quasi-truth" ]
}

@test "recursive support (short option)" {
  run bats -r "${FIXTURE_ROOT}/recursive"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..2" ]
  [ "${lines[1]}" = "ok 1 another passing test" ]
  [ "${lines[2]}" = "ok 2 a passing test" ]
}

@test "recursive support (long option)" {
  run bats --recursive "${FIXTURE_ROOT}/recursive"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..2" ]
  [ "${lines[1]}" = "ok 1 another passing test" ]
  [ "${lines[2]}" = "ok 2 a passing test" ]
}

@test "run entire suite when --filter isn't set" {
  run bats "${FIXTURE_ROOT}/filter"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '1..9' ]
  [ "${lines[1]}" = 'ok 1 foo in a' ]
  [ "${lines[2]}" = 'ok 2 --bar in a' ]
  [ "${lines[3]}" = 'ok 3 baz in a' ]
  [ "${lines[4]}" = 'ok 4 bar_in_b' ]
  [ "${lines[5]}" = 'ok 5 --baz_in_b' ]
  [ "${lines[6]}" = 'ok 6 quux_in_b' ]
  [ "${lines[7]}" = 'ok 7 quux_in c' ]
  [ "${lines[8]}" = 'ok 8 xyzzy in c' ]
  [ "${lines[9]}" = 'ok 9 plugh_in c' ]
}

@test "use --filter to run subset of test cases from across the suite" {
  run bats -f 'ba[rz]' "${FIXTURE_ROOT}/filter"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '1..4' ]
  [ "${lines[1]}" = 'ok 1 --bar in a' ]
  [ "${lines[2]}" = 'ok 2 baz in a' ]
  [ "${lines[3]}" = 'ok 3 bar_in_b' ]
  [ "${lines[4]}" = 'ok 4 --baz_in_b' ]

  local prev_output="$output"

  run bats --filter 'ba[rz]' "${FIXTURE_ROOT}/filter"
  [ "$status" -eq 0 ]
  [ "$output" = "$prev_output" ]
}

@test "--filter can handle regular expressions that contain [_- ]" {
  run bats -f '--ba[rz][ _]in' "${FIXTURE_ROOT}/filter"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '1..2' ]
  [ "${lines[1]}" = 'ok 1 --bar in a' ]
  [ "${lines[2]}" = 'ok 2 --baz_in_b' ]
}

@test "--filter can handle regular expressions that start with ^" {
  run bats -f '^ba[rz]' "${FIXTURE_ROOT}/filter"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '1..2' ]
  [ "${lines[1]}" = 'ok 1 baz in a' ]
  [ "${lines[2]}" = 'ok 2 bar_in_b' ]
}

@test "parallel suite execution with --jobs" {
  type -p parallel &>/dev/null || skip "--jobs requires GNU parallel"

  SECONDS=0
  run bats --jobs 40 "$FIXTURE_ROOT/parallel"
  duration="$SECONDS"
  [ "$status" -eq 0 ]
  # Make sure the lines are in-order.
  [[ "${lines[0]}" == "1..40" ]]
  i=0
  for s in {1..4}; do
    for t in {1..10}; do
      ((++i))
      [[ "${lines[$i]}" == "ok $i slow test $t" ]]
    done
  done
  # In theory it should take 3s, but let's give it bit of extra time instead.
  [[ "$duration" -lt 20 ]]
}
