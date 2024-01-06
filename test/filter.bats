setup() {
  load test_helper
  fixtures bats # TODO: move to own folder?
  REENTRANT_RUN_PRESERVE+=(BATS_LIBEXEC)
}

@test "Without .bats/run-logs --filter-status failed returns an error" {
  bats_require_minimum_version 1.5.0
  reentrant_run -1 bats --filter-status failed "$FIXTURE_ROOT/passing_and_failing.bats"
  [[ "${lines[0]}" == "Error: --filter-status needs '"*".bats/run-logs/' to save failed tests. Please create this folder, add it to .gitignore and try again." ]] || false
}

@test "Without previous recording --filter-status failed runs all tests and then runs only failed and missed tests" {
  cd "$BATS_TEST_TMPDIR" # don't pollute the source folder
  cp "$FIXTURE_ROOT/many_passing_and_one_failing.bats" .
  mkdir -p .bats/run-logs
  bats_require_minimum_version 1.5.0
  reentrant_run -1 --separate-stderr bats --filter-status failed "many_passing_and_one_failing.bats"
  # without previous recording, all tests should be run
  [ "${lines[0]}" == '1..4' ]
  [ "$(grep -c 'not ok' <<<"$output")" -eq 1 ]

  # shellcheck disable=SC2154
  [ "${stderr_lines[0]}" == 'No recording of previous runs found. Running all tests!' ]

  reentrant_run -1 bats --tap --filter-status failed "many_passing_and_one_failing.bats"
  # now we should only run the failing test
  [ "${lines[0]}" == 1..1 ]
  [ "${lines[1]}" == "not ok 1 a failing test" ]

  # add a new test that was missed before
  echo $'@test missed { :; }' >>"many_passing_and_one_failing.bats"

  find .bats/run-logs/ -type f -print -exec cat {} \;

  reentrant_run -1 bats --tap --filter-status failed "many_passing_and_one_failing.bats"
  # now we should only run the failing test
  [ "${lines[0]}" == 1..2 ]
  [ "${lines[1]}" == "not ok 1 a failing test" ]
  [ "${lines[4]}" == "ok 2 missed" ]
}

@test "Without previous recording --filter-status passed runs all tests and then runs only passed and missed tests" {
  cd "$BATS_TEST_TMPDIR" # don't pollute the source folder
  cp "$FIXTURE_ROOT/many_passing_and_one_failing.bats" .
  mkdir -p .bats/run-logs
  bats_require_minimum_version 1.5.0
  reentrant_run -1 bats --filter-status passed "many_passing_and_one_failing.bats"
  # without previous recording, all tests should be run
  [ "${lines[0]}" == 'No recording of previous runs found. Running all tests!' ]
  [ "${lines[1]}" == '1..4' ]
  [ "$(grep -c 'not ok' <<<"$output")" -eq 1 ]

  reentrant_run -0 bats --tap --filter-status passed "many_passing_and_one_failing.bats"
  # now we should only run the passed tests
  [ "${lines[0]}" == 1..3 ]
  [ "$(grep -c 'not ok' <<<"$output")" -eq 0 ]

  # add a new test that was missed before
  echo $'@test missed { :; }' >>"many_passing_and_one_failing.bats"

  reentrant_run -0 bats --tap --filter-status passed "many_passing_and_one_failing.bats"
  # now we should only run the passed and missed tests
  [ "${lines[0]}" == 1..4 ]
  [ "$(grep -c 'not ok' <<<"$output")" -eq 0 ]
  [ "${lines[4]}" == "ok 4 missed" ]
}

@test "Without previous recording --filter-status missed runs all tests and then runs only missed tests" {
  cd "$BATS_TEST_TMPDIR" # don't pollute the source folder
  cp "$FIXTURE_ROOT/many_passing_and_one_failing.bats" .
  mkdir -p .bats/run-logs
  bats_require_minimum_version 1.5.0
  reentrant_run -1 bats --filter-status missed "many_passing_and_one_failing.bats"
  # without previous recording, all tests should be run
  [ "${lines[0]}" == 'No recording of previous runs found. Running all tests!' ]
  [ "${lines[1]}" == '1..4' ]
  [ "$(grep -c -E '^ok' <<<"$output")" -eq 3 ]

  # add a new test that was missed before
  echo $'@test missed { :; }' >>"many_passing_and_one_failing.bats"

  reentrant_run -0 bats --tap --filter-status missed "many_passing_and_one_failing.bats"
  # now we should only run the missed test
  [ "${lines[0]}" == 1..1 ]
  [ "${lines[1]}" == "ok 1 missed" ]
}

@test "--filter-status failed gives warning on empty failed test list" {
  cd "$BATS_TEST_TMPDIR" # don't pollute the source folder
  cp "$FIXTURE_ROOT/passing.bats" .
  mkdir -p .bats/run-logs
  bats_require_minimum_version 1.5.0
  # have no failing tests
  reentrant_run -0 bats --filter-status failed "passing.bats"
  # try to run the empty list of failing tests
  reentrant_run -0 bats --filter-status failed "passing.bats"
  [ "${lines[0]}" == "There were no tests of status 'failed' in the last recorded run." ]
  [ "${lines[1]}" == "1..0" ]
  [ "${#lines[@]}" -eq 2 ]
}

enforce_own_process_group() {
  set -m
  "$@"
}

@test "--filter-status failed does not update list when run is aborted" {
  if [[ "${BATS_NUMBER_OF_PARALLEL_JOBS:-1}" -gt 1 ]]; then
    skip "Aborts don't work in parallel mode"
  fi

  cd "$BATS_TEST_TMPDIR" # don't pollute the source folder
  cp "$FIXTURE_ROOT/sigint_in_failing_test.bats" .
  mkdir -p .bats/run-logs

  bats_require_minimum_version 1.5.0
  # don't hang yet, so we get a useful rerun file
  reentrant_run -1 env DONT_ABORT=1 bats "sigint_in_failing_test.bats"

  # check that we have exactly one log
  reentrant_run find .bats/run-logs -name '*.log'
  [[ "${lines[0]}" == *.log ]] || false
  [ ${#lines[@]} -eq 1 ]

  local first_run_logs="$output"

  sleep 1 # ensure we would get different timestamps for each run

  # now rerun but abort midrun
  reentrant_run -1 enforce_own_process_group bats --rerun-failed "sigint_in_failing_test.bats"

  # should not have produced a new log
  reentrant_run find .bats/run-logs -name '*.log'
  [ "$first_run_logs" == "$output" ]
}