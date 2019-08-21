load 'test_helper'
fixtures file_setup_teardown

@test "setup_file is run once per file" {
    make_bats_test_suite_tmpdir
    export LOG="$BATS_TEST_SUITE_TMPDIR/setup_file.log"
    bats "$FIXTURE_ROOT/setup_file.bats"
}

@test "teardown_file is run once per file" {
  make_bats_test_suite_tmpdir
  export LOG="$BATS_TEST_SUITE_TMPDIR/teardown_file.log"
  run bats "$FIXTURE_ROOT/teardown_file.bats"
  [[ $status -eq 0 ]]
  # output the log for faster debugging
  cat "$LOG"
  # expect to find an entry for the tested file
  grep 'teardown_file.bats' "$LOG"
  # it should be the only entry
  run wc -l < "$LOG"
  [[ $output == 1 ]]
}

@test "setup_file is called correctly in multi file suite" {
    make_bats_test_suite_tmpdir
    export LOG="$BATS_TEST_SUITE_TMPDIR/setup_file.log"
    run bats "$FIXTURE_ROOT/setup_file.bats" "$FIXTURE_ROOT/no_setup_file.bats" "$FIXTURE_ROOT/setup_file2.bats"
    [[ $status -eq 0 ]]
    run wc -l < "$LOG"
    # each setup_file[2].bats is in the log exactly once!
    [[ $output == "2" ]]
    grep setup_file.bats "$LOG"
    grep setup_file2.bats "$LOG"
}

@test "teardown_file is called correctly in multi file suite" {
  make_bats_test_suite_tmpdir
  export LOG="$BATS_TEST_SUITE_TMPDIR/teardown_file.log"
  run bats "$FIXTURE_ROOT/teardown_file.bats" "$FIXTURE_ROOT/no_teardown_file.bats" "$FIXTURE_ROOT/teardown_file2.bats"
  [[ $status -eq 0 ]]
  run wc -l < "$LOG"
  # each teardown_file[2].bats is in the log exactly once!
  [[ $output == "2" ]]
  grep teardown_file.bats "$LOG"
  grep teardown_file2.bats "$LOG"

}

@test "setup_file failure aborts tests for this file" {
  # this might need to mark them as skipped as the test count is already determined at this point
  run bats "$FIXTURE_ROOT/setup_file_failed.bats"
  echo "$output"
  [[ $output == "1..2
not ok 1 setup_file failed
# (from function \`setup_file' in test file $RELATIVE_FIXTURE_ROOT/setup_file_failed.bats, line 2)
#   \`false' failed" ]]
}

@test "teardown_file failure fails at least one test from the file" {
  run bats "$FIXTURE_ROOT/teardown_file_failed.bats"
  [[ $status -ne 0 ]]
  echo "$output"
  [[ $output == "1..1
ok 1 test
not ok 2 teardown_file failed
# (from function \`teardown_file' in test file $RELATIVE_FIXTURE_ROOT/teardown_file_failed.bats, line 3)
#   \`false' failed" ]]
}

@test "teardown_file runs even if any test in the file failed" {
  make_bats_test_suite_tmpdir
  export LOG="$BATS_TEST_SUITE_TMPDIR/teardown_file.log"
  run bats "$FIXTURE_ROOT/teardown_file_after_failing_test.bats"
  [[ $status -ne 0 ]]
  grep teardown_file_after_failing_test.bats "$LOG"
  echo "$output"
  [[ $output == "1..1
not ok 1 failing test
# (in test file test/fixtures/file_setup_teardown/teardown_file_after_failing_test.bats, line 6)
#   \`false' failed" ]]
}

@test "teardown_file should run even after user abort via CTRL-C" {
  make_bats_test_suite_tmpdir
  export LOG="$BATS_TEST_SUITE_TMPDIR/teardown_file.log"
  STARTTIME=$SECONDS
  # guarantee that background processes get their own process group -> pid=pgid
  set -m
  # run testsubprocess in background to not avoid blocking this test
  bats "$FIXTURE_ROOT/teardown_file_after_long_test.bats"&
  SUBPROCESS_PID=$!
  # wait until we enter the test
  sleep 2
  # fake sending SIGINT (CTRL-C) to the process group of the background subprocess
  kill -SIGINT -- -$SUBPROCESS_PID
  wait # for the test to finish either way (SIGINT or normal execution)
  # check that teardown_file ran and created the log file
  [[ -f "$LOG" ]]
  grep teardown_file_after_long_test.bats "$LOG"
  # but the test must not have run to the end!
  ! grep "test finished successfully" "$LOG"
}

@test "setup_file runs even if all tests in the file are skipped" {
  make_bats_test_suite_tmpdir
  export LOG="$BATS_TEST_SUITE_TMPDIR/setup_file.log" 
  run bats "$FIXTURE_ROOT/setup_file_even_if_all_tests_are_skipped.bats"
  [[ -f "$LOG" ]]
  grep setup_file_even_if_all_tests_are_skipped.bats "$LOG"
}

@test "teardown_file runs even if all tests in the file are skipped" {
  make_bats_test_suite_tmpdir
  export LOG="$BATS_TEST_SUITE_TMPDIR/teardown_file.log" 
  run bats "$FIXTURE_ROOT/teardown_file_even_if_all_tests_are_skipped.bats"
  [[ $status -eq 0 ]]
  [[ -f "$LOG" ]]
  grep teardown_file_even_if_all_tests_are_skipped.bats "$LOG"
}

@test "setup_file must not leak context between tests in the same suite" {
  # example: BATS_ROOT was unset in one test but used in others, therefore, the suite failed
  # Simulate leaking env var from first to second test by: export SETUP_FILE_VAR="LEAK!"
  run bats "$FIXTURE_ROOT/setup_file_does_not_leak_env.bats" "$FIXTURE_ROOT/setup_file_does_not_leak_env2.bats"
  [[ $status -eq 0 ]] || (echo $output; return 1)
}

@test "teardown_file must not leak context between tests in the same suite" {
  # example: BATS_ROOT was unset in one test but used in others, therefore, the suite failed
  run bats "$FIXTURE_ROOT/teardown_file_does_not_leak.bats" "$FIXTURE_ROOT/teardown_file_does_not_leak2.bats"
  echo "$output"
  [[ $status -eq 0 ]]
  [[ $output == "1..2
ok 1 test
ok 2 must not see variable from first run" ]]
}

@test "halfway setup_file errors are caught and reported" {
  run bats "$FIXTURE_ROOT/setup_file_halfway_error.bats"
  [[ $status -ne 0 ]]
  echo "$output"
  [[ "$output" == "1..1
not ok 1 setup_file failed
# (from function \`setup_file' in test file test/fixtures/file_setup_teardown/setup_file_halfway_error.bats, line 3)
#   \`false' failed" ]]
}

@test "halfway teardown_file errors are caught and reported" {
  run bats "$FIXTURE_ROOT/teardown_file_halfway_error.bats"
  echo "$output"
  [[ $status -ne 0 ]]
  [[ "$output" == "1..1
ok 1 empty
not ok 2 teardown_file failed
# (from function \`teardown_file' in test file $RELATIVE_FIXTURE_ROOT/teardown_file_halfway_error.bats, line 3)
#   \`false' failed" ]]
}