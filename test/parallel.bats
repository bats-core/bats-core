#!/usr/bin/env bats

load test_helper
fixtures parallel

setup() {
  type -p parallel &>/dev/null || skip "--jobs requires GNU parallel"
}

@test "parallel test execution with --jobs" {
  export FILE_MARKER=$(mktemp)
  
  run bats --jobs 10 "$FIXTURE_ROOT/parallel.bats"
  
  [ "$status" -eq 0 ]
  # Make sure the lines are in-order.
  [[ "${lines[0]}" == "1..10" ]]
  for t in {1..10}; do
    [[ "${lines[$t]}" == "ok $t slow test $t" ]]
  done

  max_parallel_tests=0
  started_tests=0
  read_lines=0
  while IFS= read -r line; do
    (( ++read_lines ))
    case "$line" in
      setup*)
        if (( ++started_tests > max_parallel_tests )); then
          max_parallel_tests="$started_tests"
        fi
      ;;
      teardown*)
        (( started_tests-- ))
      ;;
    esac
  done <"$FILE_MARKER"

  echo "max_parallel_tests: $max_parallel_tests"
  [[ $max_parallel_tests -eq 10 ]]

  echo "read_lines: $read_lines"
  [[ $read_lines -eq 20 ]]
}

@test "parallel can preserve environment variables" {
  export TEST_ENV_VARIABLE='test-value'
  run bats --jobs 2 "$FIXTURE_ROOT/parallel-preserve-environment.bats"
  echo "$output"
  [[ "$status" -eq 0 ]]
}

@test "parallel suite execution with --jobs" {
  export FILE_MARKER=$(mktemp)
  run bash -c "bats --jobs 40 \"${FIXTURE_ROOT}/suite/\" 2> >(grep -v '^parallel: Warning: ')"

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

  max_parallel_tests=0
  started_tests=0
  read_lines=0
  while IFS= read -r line; do
    (( ++read_lines ))
    case "$line" in
      setup*)
        if (( ++started_tests > max_parallel_tests )); then
          max_parallel_tests="$started_tests"
        fi
      ;;
      teardown*)
        (( started_tests-- ))
      ;;
    esac
  done <"$FILE_MARKER"

  echo "max_parallel_tests: $max_parallel_tests"
  [[ $max_parallel_tests -eq 40 ]]

  echo "read_lines: $read_lines"
  [[ $read_lines -eq 80 ]]
}

@test "setup_file is not over parallelized" {
  export FILE_MARKER=$(mktemp)
  # run 4 files with 3s sleeps in setup_file with parallelity of 2 -> serialize 2
  run bats --jobs 2 "$FIXTURE_ROOT/setup_file"

  cat "$FILE_MARKER"

  [[ $(grep -c "setup_file " "$FILE_MARKER") -eq 4 ]] # beware of grepping the filename as well!
  [[ $(grep -c teardown_file "$FILE_MARKER") -eq 4 ]]

  max_parallel_files=0
  started_files=0
  read_lines=0
  while IFS= read -r line; do
    (( ++read_lines ))
    case "$line" in
      setup_file*)
        if (( ++started_files > max_parallel_files )); then
          max_parallel_files="$started_files"
        fi
      ;;
      teardown_file*)
        (( started_files-- ))
      ;;
    esac
  done <"$FILE_MARKER"

  echo "max_parallel_files: $max_parallel_files"
  [[ $max_parallel_files -eq 2 ]]

  echo "read_lines: $read_lines"
  [[ $read_lines -eq 8 ]]
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
  # ensure that we really run parallelization across files!
  # (setup should have skipped already, if there was no GNU parallel)
  unset BATS_NO_PARALLELIZE_ACROSS_FILES
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
  # ensure that we really run parallelization across files!
  # (setup should have skipped already, if there was no GNU parallel)
  unset BATS_NO_PARALLELIZE_ACROSS_FILES
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