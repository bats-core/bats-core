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
  export TEST_ENV_VARIABLE='test-value'
  run bats --jobs 2 "$FIXTURE_ROOT/parallel-preserve-environment.bats"
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
  [[ $duration -le 9 ]]
}

@test "running the same file twice runs its tests twice without errors" {
  run bats --jobs 2 "$FIXTURE_ROOT/../bats/passing.bats" "$FIXTURE_ROOT/../bats/passing.bats"
  echo "$output"
  [[ $status -eq 0 ]]
  [[ "${lines[0]}" == "1..2" ]] # got 2x1 tests
  [[ "${lines[1]}" == "ok 1 "* ]]
  [[ "${lines[2]}" == "ok 2 "* ]]
  [[ "${#lines[@]}" -eq 3 ]]
}

@test "parallelity factor is met exactly" {
  parallelity=5 # run the 10 tests in 2 batches with 5 test each
  bats --jobs $parallelity "$FIXTURE_ROOT/parallel_factor.bats" & # run in background to avoid blocking
  # give it some time to start the tests
  sleep 2
  # find how many semaphores are started in parallel; don't count grep itself
  run bash -c "ps -ef | grep bats-exec-test | grep parallel/parallel_factor.bats | grep -v grep"
  echo "$output"
  
  # This might fail spuriously if we got bad luck with the scheduler
  # and hit the transition between the first and second batch of tests.
  [[ "${#lines[@]}" -eq $parallelity  ]]
}

@test "parallel mode correctly forwards failure return code" {
  run bats --jobs 2 "$FIXTURE_ROOT/../bats/failing.bats"
  [[ "$status" -eq 1 ]]
}

@test "--no-parallelize-across-files test file detects parallel execution" {
  export FILE_MARKER=$(mktemp)
  ! bats --jobs 2 "$FIXTURE_ROOT/must_not_parallelize_across_files/"
}

@test "--no-parallelize-across-files prevents parallelization across files" {
  export FILE_MARKER=$(mktemp)
  bats --jobs 2 --no-parallelize-across-files "$FIXTURE_ROOT/must_not_parallelize_across_files/"
}

@test "--no-parallelize-across-files does not prevent parallelization within files" {
  ! bats --jobs 2 --no-parallelize-across-files "$FIXTURE_ROOT/must_not_parallelize_within_file.bats"
}

@test "--no-parallelize-within-files test file detects parallel execution" {
  ! bats --jobs 2 "$FIXTURE_ROOT/must_not_parallelize_within_file.bats"
}

@test "--no-parallelize-within-files prevents parallelization within files" {
  bats --jobs 2 --no-parallelize-within-files "$FIXTURE_ROOT/must_not_parallelize_within_file.bats"
}

@test "--no-parallelize-within-files does not prevent parallelization across files" {
  export FILE_MARKER=$(mktemp)
  ! bats --jobs 2 --no-parallelize-within-files "$FIXTURE_ROOT/must_not_parallelize_across_files/"
}

@test "BATS_NO_PARALLELIZE_WITHIN_FILE works from inside setup_file()" {
  DISABLE_IN_SETUP_FILE_FUNCTION=1 bats --jobs 2 "$FIXTURE_ROOT/must_not_parallelize_within_file.bats"
}

@test "BATS_NO_PARALLELIZE_WITHIN_FILE works from outside all functions" {
  DISABLE_OUTSIDE_ALL_FUNCTIONS=1 bats --jobs 2 "$FIXTURE_ROOT/must_not_parallelize_within_file.bats"
}

@test "BATS_NO_PARALLELIZE_WITHIN_FILE does not work from inside setup()" {
  ! DISABLE_IN_SETUP_FUNCTION=1 bats --jobs 2 "$FIXTURE_ROOT/must_not_parallelize_within_file.bats"
}

@test "BATS_NO_PARALLELIZE_WITHIN_FILE does not work from inside test function" {
  ! DISABLE_IN_TEST_FUNCTION=1 bats --jobs 2 "$FIXTURE_ROOT/must_not_parallelize_within_file.bats"
}