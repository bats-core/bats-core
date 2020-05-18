#!/usr/bin/env bats

load test_helper
fixtures parallel

setup() {
    type -p parallel &>/dev/null || skip "--jobs requires GNU parallel"
}

@test "parallel test execution with --jobs" {
  SECONDS=0
  run bats --jobs 10 "$FIXTURE_ROOT/parallel.bats"
  duration="$SECONDS"
  [ "$status" -eq 0 ]
  # Make sure the lines are in-order.
  [[ "${lines[0]}" == "1..10" ]]
  for t in {1..10}; do
    [[ "${lines[$t]}" == "ok $t slow test $t" ]]
  done
  # In theory it should take 3s, but let's give it bit of extra time instead.
  [[ "$duration" -lt 20 ]]
}

@test "parallel can preserve environment variables" {
  if [[ ! -e ~/.parallel/ignored_vars ]]; then
    parallel --record-env
    PARALLEL_WAS_SETUP=1
  fi
  export TEST_ENV_VARIABLE='test-value'
  run bats --jobs 1 --parallel-preserve-environment "$FIXTURE_ROOT/parallel-preserve-environment.bats"
  if [[ $PARALLEL_WAS_SETUP ]]; then
    rm ~/.parallel/ignored_vars
  fi
  echo "$output"
  [[ "$status" -eq 0 ]]
}

@test "parallel suite execution with --jobs" {
  SECONDS=0
  run bash -c "bats --jobs 40 \"${FIXTURE_ROOT}/suite/\" 2> >(grep -v '^parallel: Warning: ')"

  duration="$SECONDS"
  echo "$output"
  echo "Duration: $duration"
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
  # In theory it should take 3s, but let's give it bit of extra time for load tolerance.
  # (Since there is no limit to load, we cannot totally avoid erroneous failures by limited tolerance.)
  # Also check that parallelization happens across all files instead of
  # linearizing between files, which requires at least 12s
  [[ "$duration" -lt 12 ]] || (echo "If this fails on Travis, make sure the failure is repeatable and not due to heavy load."; false)
}

@test "setup_file is not over parallelized" {
  SECONDS=0
  # run 4 files with 3s sleeps in setup_file with parallelity of 2 -> serialize 2
  run bats --jobs 2 "$FIXTURE_ROOT/setup_file"
  duration="$SECONDS"
  echo "Took $duration seconds"
  [ "$status" -eq 0 ]
  # the serialization should lead to at least 6s runtime
  [[ $duration -ge 6 ]]
  # parallelization should at least get rid of 1/4th the total runtime
  [[ $duration -lt 9 ]]
}
