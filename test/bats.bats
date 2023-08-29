#!/usr/bin/env bats

setup() {
  load test_helper
  fixtures bats
  REENTRANT_RUN_PRESERVE+=(BATS_LIBEXEC)
}

@test "no arguments prints message and usage instructions" {
  reentrant_run bats
  [ $status -eq 1 ]
  [ "${lines[0]}" == 'Error: Must specify at least one <test>' ]
  [ "${lines[1]%% *}" == 'Usage:' ]
}

@test "invalid option prints message and usage instructions" {
  reentrant_run bats --invalid-option
  [ $status -eq 1 ]
  [ "${lines[0]}" == "Error: Bad command line option '--invalid-option'" ]
  [ "${lines[1]%% *}" == 'Usage:' ]
}

@test "-v and --version print version number" {
  reentrant_run bats -v
  [ $status -eq 0 ]
  [ "$(expr "$output" : "Bats [0-9][0-9.]*")" -ne 0 ]
}

@test "-h and --help print help" {
  reentrant_run bats -h
  [ $status -eq 0 ]
  [ "${#lines[@]}" -gt 3 ]
}

@test "invalid filename prints an error" {
  reentrant_run bats nonexistent
  [ $status -eq 1 ]
  [ "$(expr "$output" : ".*does not exist")" -ne 0 ]
}

@test "empty test file runs zero tests" {
  reentrant_run bats "$FIXTURE_ROOT/empty.bats"
  [ $status -eq 0 ]
  [ "$output" = "1..0" ]
}

@test "one passing test" {
  reentrant_run bats "$FIXTURE_ROOT/passing.bats"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..1" ]
  [ "${lines[1]}" = "ok 1 a passing test" ]
}

@test "summary passing tests" {
  reentrant_run filter_control_sequences bats -p "$FIXTURE_ROOT/passing.bats"
  echo "$output"
  [ $status -eq 0 ]
  [ "${lines[2]}" = "1 test, 0 failures" ]
}

@test "summary passing and skipping tests" {
  reentrant_run filter_control_sequences bats -p "$FIXTURE_ROOT/passing_and_skipping.bats"
  [ $status -eq 0 ]
  [ "${lines[4]}" = "3 tests, 0 failures, 2 skipped" ]
}

@test "summary passing and failing tests" {
  reentrant_run filter_control_sequences bats -p "$FIXTURE_ROOT/failing_and_passing.bats"
  [ $status -eq 0 ]
  [ "${lines[5]}" = "2 tests, 1 failure" ]
}

@test "summary passing, failing and skipping tests" {
  reentrant_run filter_control_sequences bats -p "$FIXTURE_ROOT/passing_failing_and_skipping.bats"
  [ $status -eq 0 ]
  [ "${lines[6]}" = "3 tests, 1 failure, 1 skipped" ]
}

@test "BATS_CWD is correctly set to PWD as validated by bats_trim_filename" {
  local trimmed
  bats_trim_filename "$PWD/foo/bar" 'trimmed'
  printf 'ACTUAL: %s\n' "$trimmed" >&2
  [ "$trimmed" = 'foo/bar' ]
}

@test "one failing test" {
  reentrant_run bats "$FIXTURE_ROOT/failing.bats"
  [ $status -eq 1 ]
  [ "${lines[0]}" = '1..1' ]
  [ "${lines[1]}" = 'not ok 1 a failing test' ]
  [ "${lines[2]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/failing.bats, line 4)" ]
  [ "${lines[3]}" = "#   \`eval \"( exit \${STATUS:-1} )\"' failed" ]
}

@test "one failing and one passing test" {
  reentrant_run bats "$FIXTURE_ROOT/failing_and_passing.bats"
  [ $status -eq 1 ]
  [ "${lines[0]}" = '1..2' ]
  [ "${lines[1]}" = 'not ok 1 a failing test' ]
  [ "${lines[2]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/failing_and_passing.bats, line 2)" ]
  [ "${lines[3]}" = "#   \`false' failed" ]
  [ "${lines[4]}" = 'ok 2 a passing test' ]
}

@test "failing test with significant status" {
  STATUS=2 reentrant_run bats "$FIXTURE_ROOT/failing.bats"
  [ $status -eq 1 ]
  [ "${lines[3]}" = "#   \`eval \"( exit \${STATUS:-1} )\"' failed with status 2" ]
}

@test "failing helper function logs the test case's line number" {
  reentrant_run bats "$FIXTURE_ROOT/failing_helper.bats"
  [ $status -eq 1 ]
  [ "${lines[1]}" = 'not ok 1 failing helper function' ]
  [ "${lines[2]}" = "# (from function \`failing_helper' in file $RELATIVE_FIXTURE_ROOT/test_helper.bash, line 6," ]
  [ "${lines[3]}" = "#  in test file $RELATIVE_FIXTURE_ROOT/failing_helper.bats, line 5)" ]
  [ "${lines[4]}" = "#   \`failing_helper' failed" ]
}

@test "failing bash condition logs correct line number" {
  reentrant_run bats "$FIXTURE_ROOT/failing_with_bash_cond.bats"
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 4 ]
  [ "${lines[1]}" = 'not ok 1 a failing test' ]
  [ "${lines[2]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/failing_with_bash_cond.bats, line 4)" ]
  [ "${lines[3]}" = "#   \`[[ 1 == 2 ]]' failed" ]
}

@test "failing bash expression logs correct line number" {
  reentrant_run bats "$FIXTURE_ROOT/failing_with_bash_expression.bats"
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 4 ]
  [ "${lines[1]}" = 'not ok 1 a failing test' ]
  [ "${lines[2]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/failing_with_bash_expression.bats, line 3)" ]
  [ "${lines[3]}" = "#   \`((1 == 2))' failed" ]
}

@test "failing negated command logs correct line number" {
  reentrant_run bats "$FIXTURE_ROOT/failing_with_negated_command.bats"
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 4 ]
  [ "${lines[1]}" = 'not ok 1 a failing test' ]
  [ "${lines[2]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/failing_with_negated_command.bats, line 4)" ]
  [ "${lines[3]}" = "#   \`! true' failed" ]
}

@test "test environments are isolated" {
  reentrant_run bats "$FIXTURE_ROOT/environment.bats"
  [ $status -eq 0 ]
}

@test "setup is run once before each test" {
  unset BATS_NUMBER_OF_PARALLEL_JOBS BATS_NO_PARALLELIZE_ACROSS_FILES

  # shellcheck disable=SC2031,SC2030
  export BATS_TEST_SUITE_TMPDIR="${BATS_TEST_TMPDIR}"
  # shellcheck disable=SC2030
  REENTRANT_RUN_PRESERVE+=(BATS_TEST_SUITE_TMPDIR)

  reentrant_run bats "$FIXTURE_ROOT/setup.bats"
  [ $status -eq 0 ]
  reentrant_run cat "$BATS_TEST_SUITE_TMPDIR/setup.log"
  [ ${#lines[@]} -eq 3 ]
}

@test "teardown is run once after each test, even if it fails" {
  unset BATS_NUMBER_OF_PARALLEL_JOBS BATS_NO_PARALLELIZE_ACROSS_FILES

  # shellcheck disable=SC2031,SC2030
  export BATS_TEST_SUITE_TMPDIR="${BATS_TEST_TMPDIR}"
  # shellcheck disable=SC2030,SC2031
  REENTRANT_RUN_PRESERVE+=(BATS_TEST_SUITE_TMPDIR)

  reentrant_run bats "$FIXTURE_ROOT/teardown.bats"
  [ $status -eq 1 ]
  reentrant_run cat "$BATS_TEST_SUITE_TMPDIR/teardown.log"
  [ ${#lines[@]} -eq 3 ]
}

@test "setup failure" {
  reentrant_run bats "$FIXTURE_ROOT/failing_setup.bats"
  [ $status -eq 1 ]
  [ "${lines[1]}" = 'not ok 1 truth' ]
  [ "${lines[2]}" = "# (from function \`setup' in test file $RELATIVE_FIXTURE_ROOT/failing_setup.bats, line 2)" ]
  [ "${lines[3]}" = "#   \`false' failed" ]
}

@test "passing test with teardown failure" {
  PASS=1 reentrant_run bats "$FIXTURE_ROOT/failing_teardown.bats"
  [ $status -eq 1 ]
  echo "$output"
  [ "${lines[1]}" = 'not ok 1 truth' ]
  [ "${lines[2]}" = "# (from function \`teardown' in test file $RELATIVE_FIXTURE_ROOT/failing_teardown.bats, line 2)" ]
  [ "${lines[3]}" = "#   \`eval \"( exit \${STATUS:-1} )\"' failed" ]
}

@test "failing test with teardown failure" {
  PASS=0 reentrant_run bats "$FIXTURE_ROOT/failing_teardown.bats"
  [ $status -eq 1 ]
  [ "${lines[1]}" = 'not ok 1 truth' ]
  [ "${lines[2]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/failing_teardown.bats, line 6)" ]
  [ "${lines[3]}" = $'#   `[ "$PASS" = 1 ]\' failed' ]
}

@test "teardown failure with significant status" {
  PASS=1 STATUS=2 reentrant_run bats "$FIXTURE_ROOT/failing_teardown.bats"
  [ $status -eq 1 ]
  [ "${lines[3]}" = "#   \`eval \"( exit \${STATUS:-1} )\"' failed with status 2" ]
}

@test "failing test file outside of BATS_CWD" {
  cd "${BATS_TEST_TMPDIR}"
  reentrant_run bats "$FIXTURE_ROOT/failing.bats"
  [ $status -eq 1 ]
  [ "${lines[2]}" = "# (in test file $FIXTURE_ROOT/failing.bats, line 4)" ]
}

@test "output is discarded for passing tests and printed for failing tests" {
  reentrant_run bats "$FIXTURE_ROOT/output.bats"
  [ $status -eq 1 ]
  [ "${lines[6]}" = '# failure stdout 1' ]
  [ "${lines[7]}" = '# failure stdout 2' ]
  [ "${lines[11]}" = '# failure stderr' ]
}

@test "-c prints the number of tests" {
  reentrant_run bats -c "$FIXTURE_ROOT/empty.bats"
  [ $status -eq 0 ]
  [ "$output" = 0 ]

  reentrant_run bats -c "$FIXTURE_ROOT/output.bats"
  [ $status -eq 0 ]
  [ "$output" = 4 ]
}

@test "dash-e is not mangled on beginning of line" {
  reentrant_run bats "$FIXTURE_ROOT/intact.bats"
  [ $status -eq 0 ]
  [ "${lines[1]}" = "ok 1 dash-e on beginning of line" ]
}

@test "dos line endings are stripped before testing" {
  reentrant_run bats "$FIXTURE_ROOT/dos_line_no_shellcheck.bats"
  [ $status -eq 0 ]
}

@test "test file without trailing newline" {
  reentrant_run bats "$FIXTURE_ROOT/without_trailing_newline.bats"
  [ $status -eq 0 ]
  [ "${lines[1]}" = "ok 1 truth" ]
}

@test "skipped tests" {
  reentrant_run bats "$FIXTURE_ROOT/skipped.bats"
  [ $status -eq 0 ]
  [ "${lines[1]}" = "ok 1 a skipped test # skip" ]
  [ "${lines[2]}" = "ok 2 a skipped test with a reason # skip a reason" ]
}

@test "extended syntax" {
  emulate_bats_env
  # shellcheck disable=SC2030,SC2031
  REENTRANT_RUN_PRESERVE+=(BATS_LINE_REFERENCE_FORMAT)
  reentrant_run bats-exec-suite -x "$FIXTURE_ROOT/failing_and_passing.bats"
  echo "$output"
  [ $status -eq 1 ]
  [ "${lines[1]}" = "suite $FIXTURE_ROOT/failing_and_passing.bats" ]
  [ "${lines[2]}" = 'begin 1 a failing test' ]
  [ "${lines[3]}" = 'not ok 1 a failing test' ]
  [ "${lines[6]}" = 'begin 2 a passing test' ]
  [ "${lines[7]}" = 'ok 2 a passing test' ]
}

@test "timing syntax" {
  reentrant_run bats -T "$FIXTURE_ROOT/failing_and_passing.bats"
  echo "$output"
  [ $status -eq 1 ]
  regex='not ok 1 a failing test in [0-9]+ms'
  [[ "${lines[1]}" =~ $regex ]]
  regex='ok 2 a passing test in [0-9]+ms'
  [[ "${lines[4]}" =~ $regex ]]
}

@test "extended timing syntax" {
  emulate_bats_env
  # shellcheck disable=SC2030,SC2031
  REENTRANT_RUN_PRESERVE+=(BATS_LINE_REFERENCE_FORMAT)
  reentrant_run bats-exec-suite -x -T "$FIXTURE_ROOT/failing_and_passing.bats"
  echo "$output"
  [ $status -eq 1 ]
  regex="not ok 1 a failing test in [0-9]+ms"
  [ "${lines[2]}" = 'begin 1 a failing test' ]
  [[ "${lines[3]}" =~ $regex ]]
  [ "${lines[6]}" = 'begin 2 a passing test' ]
  regex="ok 2 a passing test in [0-9]+ms"
  [[ "${lines[7]}" =~ $regex ]]
}

@test "time is greater than 0ms for long test" {
  emulate_bats_env
  # shellcheck disable=SC2030,SC2031
  REENTRANT_RUN_PRESERVE+=(BATS_LINE_REFERENCE_FORMAT)
  reentrant_run bats-exec-suite -x -T "$FIXTURE_ROOT/run_long_command.bats"
  echo "$output"
  [ $status -eq 0 ]
  regex="ok 1 run long command in [1-9][0-9]*ms"
  [[ "${lines[3]}" =~ $regex ]]
}

@test "single-line tests" {
  reentrant_run bats --no-tempdir-cleanup "$FIXTURE_ROOT/single_line_no_shellcheck.bats"
  [ $status -eq 1 ]
  [ "${lines[1]}" = 'ok 1 empty' ]
  [ "${lines[2]}" = 'ok 2 passing' ]
  [ "${lines[3]}" = 'ok 3 input redirection' ]
  [ "${lines[4]}" = 'not ok 4 failing' ]
  [ "${lines[5]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/single_line_no_shellcheck.bats, line 9)" ]
  [ "${lines[6]}" = $'#   `@test "failing" { false; }\' failed' ]
}

@test "testing IFS not modified by run" {
  reentrant_run bats "$FIXTURE_ROOT/loop_keep_IFS.bats"
  [ $status -eq 0 ]
  [ "${lines[1]}" = "ok 1 loop_func" ]
}

@test "expand variables in test name" {
  SUITE='test/suite' reentrant_run bats "$FIXTURE_ROOT/expand_var_in_test_name.bats"
  [ $status -eq 0 ]
  [ "${lines[1]}" = "ok 1 test/suite: test with variable in name" ]
}

@test "handle quoted and unquoted test names" {
  reentrant_run bats "$FIXTURE_ROOT/quoted_and_unquoted_test_names_no_shellcheck.bats"
  [ $status -eq 0 ]
  [ "${lines[1]}" = "ok 1 single-quoted name" ]
  [ "${lines[2]}" = "ok 2 double-quoted name" ]
  [ "${lines[3]}" = "ok 3 unquoted name" ]
}

@test 'ensure compatibility with unofficial Bash strict mode' {
  local expected='ok 1 unofficial Bash strict mode conditions met'

  if [[ -n "${BATS_NUMBER_OF_PARALLEL_JOBS:-}" ]]; then
    if [[ -z "${BATS_NO_PARALLELIZE_ACROSS_FILES:-}" ]]; then
      type -p parallel &>/dev/null || skip "Don't check file parallelized without GNU parallel"
    fi
    (type -p flock &>/dev/null || type -p shlock &>/dev/null) || skip "Don't check parallelized without flock/shlock "
  fi

  # PATH required for windows
  # HOME required to avoid error from GNU Parallel
  # Run Bats under SHELLOPTS=nounset (recursive `set -u`) to catch
  # as many unset variable accesses as possible.
  run env - \
    "PATH=$PATH" \
    "HOME=$HOME" \
    "BATS_NO_PARALLELIZE_ACROSS_FILES=${BATS_NO_PARALLELIZE_ACROSS_FILES:-}" \
    "BATS_NUMBER_OF_PARALLEL_JOBS=${BATS_NUMBER_OF_PARALLEL_JOBS:-}" \
    SHELLOPTS=nounset \
    "${BATS_ROOT}/bin/bats" "$FIXTURE_ROOT/unofficial_bash_strict_mode.bats"
  if [[ "$status" -ne 0 || "${lines[1]}" != "$expected" ]]; then
    cat <<END_OF_ERR_MSG

This test failed because the Bats internals are violating one of the
constraints imposed by:

--------
$(<"$FIXTURE_ROOT/unofficial_bash_strict_mode.bash")
--------

See:
- https://github.com/sstephenson/bats/issues/171
- http://redsymbol.net/articles/unofficial-bash-strict-mode/

If there is no error output from the test fixture, run the following to
debug the problem:

  $ SHELLOPTS=nounset bats $RELATIVE_FIXTURE_ROOT/unofficial_bash_strict_mode.bats

If there's no error output even with this command, make sure you're using the
latest version of Bash, as versions before 4.1-alpha may not produce any error
output for unset variable accesses.

If there's no output even when running the latest Bash, the problem may reside
in the DEBUG trap handler. A particularly sneaky issue is that in Bash before
4.1-alpha, an expansion of an empty array, e.g. "\${FOO[@]}", is considered
an unset variable access. The solution is to add a size check before the
expansion, e.g. [[ "\${#FOO[@]}" -ne 0 ]].

END_OF_ERR_MSG
    emit_debug_output && return 1
  fi
}

@test "parse @test lines with various whitespace combinations" {
  reentrant_run bats "$FIXTURE_ROOT/whitespace_no_shellcheck.bats"
  [ $status -eq 0 ]
  [ "${lines[1]}" = 'ok 1 no extra whitespace' ]
  [ "${lines[2]}" = 'ok 2 tab at beginning of line' ]
  [ "${lines[3]}" = 'ok 3 tab before description' ]
  [ "${lines[4]}" = 'ok 4 tab before opening brace' ]
  [ "${lines[5]}" = 'ok 5 tabs at beginning of line and before description' ]
  [ "${lines[6]}" = 'ok 6 tabs at beginning, before description, before brace' ]
  [ "${lines[7]}" = 'ok 7 extra whitespace around single-line test' ]
  [ "${lines[8]}" = 'ok 8 no extra whitespace around single-line test' ]
  [ "${lines[9]}" = 'ok 9 parse unquoted name between extra whitespace' ]
  [ "${lines[10]}" = 'ok 10 {' ] # unquoted single brace is a valid description
  [ "${lines[11]}" = 'ok 11 ' ]  # empty name from single quote
}

@test "duplicate tests error and generate a warning on stderr" {
  reentrant_run bats --tap "$FIXTURE_ROOT/duplicate-tests_no_shellcheck.bats"
  [ $status -eq 1 ]

  local expected='Error: Duplicate test name(s) in file '
  expected+="\"${FIXTURE_ROOT}/duplicate-tests_no_shellcheck.bats\": test_gizmo_test"

  printf 'expected: "%s"\n' "$expected" >&2
  printf 'actual:   "%s"\n' "${lines[0]}" >&2
  [ "${lines[0]}" = "$expected" ]

  printf 'num lines: %d\n' "${#lines[*]}" >&2
  [ "${#lines[*]}" = "1" ]
}

@test "sourcing a nonexistent file in setup produces error output" {
  reentrant_run bats "$FIXTURE_ROOT/source_nonexistent_file_in_setup.bats"
  [ $status -eq 1 ]
  [ "${lines[1]}" = 'not ok 1 sourcing nonexistent file fails in setup' ]
  [ "${lines[2]}" = "# (from function \`setup' in test file $RELATIVE_FIXTURE_ROOT/source_nonexistent_file_in_setup.bats, line 3)" ]
  [ "${lines[3]}" = "#   \`source \"nonexistent file\"' failed" ]
}

@test "referencing unset parameter in setup produces error output" {
  reentrant_run bats "$FIXTURE_ROOT/reference_unset_parameter_in_setup.bats"
  [ $status -eq 1 ]
  [ "${lines[1]}" = 'not ok 1 referencing unset parameter fails in setup' ]
  [ "${lines[2]}" = "# (from function \`setup' in test file $RELATIVE_FIXTURE_ROOT/reference_unset_parameter_in_setup.bats, line 4)" ]
  [ "${lines[3]}" = "#   \`echo \"\$unset_parameter\"' failed" ]
}

@test "sourcing a nonexistent file in test produces error output" {
  reentrant_run bats "$FIXTURE_ROOT/source_nonexistent_file.bats"
  [ $status -eq 1 ]
  [ "${lines[1]}" = 'not ok 1 sourcing nonexistent file fails' ]
  [ "${lines[2]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/source_nonexistent_file.bats, line 3)" ]
  [ "${lines[3]}" = "#   \`source \"nonexistent file\"' failed" ]
}

@test "referencing unset parameter in test produces error output" {
  reentrant_run bats "$FIXTURE_ROOT/reference_unset_parameter.bats"
  [ $status -eq 1 ]
  [ "${lines[1]}" = 'not ok 1 referencing unset parameter fails' ]
  [ "${lines[2]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/reference_unset_parameter.bats, line 4)" ]
  [ "${lines[3]}" = "#   \`echo \"\$unset_parameter\"' failed" ]
}

@test "sourcing a nonexistent file in teardown produces error output" {
  reentrant_run bats "$FIXTURE_ROOT/source_nonexistent_file_in_teardown.bats"
  [ $status -eq 1 ]
  [ "${lines[1]}" = 'not ok 1 sourcing nonexistent file fails in teardown' ]
  [ "${lines[2]}" = "# (from function \`teardown' in test file $RELATIVE_FIXTURE_ROOT/source_nonexistent_file_in_teardown.bats, line 3)" ]
  [ "${lines[3]}" = "#   \`source \"nonexistent file\"' failed" ]
}

@test "referencing unset parameter in teardown produces error output" {
  reentrant_run bats "$FIXTURE_ROOT/reference_unset_parameter_in_teardown.bats"
  [ $status -eq 1 ]
  [ "${lines[1]}" = 'not ok 1 referencing unset parameter fails in teardown' ]
  [ "${lines[2]}" = "# (from function \`teardown' in test file $RELATIVE_FIXTURE_ROOT/reference_unset_parameter_in_teardown.bats, line 4)" ]
  [ "${lines[3]}" = "#   \`echo \"\$unset_parameter\"' failed" ]
}

@test "execute exported function without breaking failing test output" {
  exported_function() { return 0; }
  export -f exported_function
  reentrant_run bats "$FIXTURE_ROOT/exported_function.bats"
  [ $status -eq 1 ]
  [ "${lines[0]}" = "1..1" ]
  [ "${lines[1]}" = "not ok 1 failing test" ]
  [ "${lines[2]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/exported_function.bats, line 7)" ]
  [ "${lines[3]}" = "#   \`false' failed" ]
  [ "${lines[4]}" = "# a='exported_function'" ]
}

@test "output printed even when no final newline" {
  reentrant_run bats "$FIXTURE_ROOT/no-final-newline.bats"
  printf 'num lines: %d\n' "${#lines[@]}" >&2
  printf 'LINE: %s\n' "${lines[@]}" >&2
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 11 ]
  [ "${lines[1]}" = 'not ok 1 error in test' ]
  [ "${lines[2]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/no-final-newline.bats, line 3)" ]
  [ "${lines[3]}" = "#   \`false' failed" ]
  [ "${lines[4]}" = '# foo' ]
  [ "${lines[5]}" = '# bar' ]
  [ "${lines[6]}" = 'not ok 2 test function returns nonzero' ]
  [ "${lines[7]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/no-final-newline.bats, line 8)" ]
  [ "${lines[8]}" = "#   \`return 1' failed" ]
  [ "${lines[9]}" = '# foo' ]
  [ "${lines[10]}" = '# bar' ]
}

@test "run tests which consume stdin (see #197)" {
  reentrant_run bats "$FIXTURE_ROOT/read_from_stdin.bats"
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == "1..3" ]]
  [[ "${lines[1]}" == "ok 1 test 1" ]]
  [[ "${lines[2]}" == "ok 2 test 2 with	TAB in name" ]]
  [[ "${lines[3]}" == "ok 3 test 3" ]]
}

@test "report correct line on unset variables" {
  LANG=C reentrant_run bats "$FIXTURE_ROOT/unbound_variable.bats"
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 9 ]
  [ "${lines[1]}" = 'not ok 1 access unbound variable' ]
  [ "${lines[2]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/unbound_variable.bats, line 9)" ]
  [ "${lines[3]}" = "#   \`foo=\$unset_variable' failed" ]
  # shellcheck disable=SC2076
  [[ "${lines[4]}" =~ ".bats: line 9:" ]]
  [ "${lines[5]}" = 'not ok 2 access second unbound variable' ]
  [ "${lines[6]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/unbound_variable.bats, line 15)" ]
  [ "${lines[7]}" = "#   \`foo=\$second_unset_variable' failed" ]
  # shellcheck disable=SC2076
  [[ "${lines[8]}" =~ ".bats: line 15:" ]]
}

@test "report correct line on external function calls" {
  reentrant_run bats "$FIXTURE_ROOT/external_function_calls.bats"
  [ "$status" -eq 1 ]

  expectedNumberOfTests=12
  linesPerTest=6

  outputOffset=1
  currentErrorLine=9

  for t in $(seq $expectedNumberOfTests); do
    echo "t=$t outputOffset=$outputOffset currentErrorLine=$currentErrorLine"
    # shellcheck disable=SC2076
    [[ "${lines[$outputOffset]}" =~ "not ok $t " ]]

    [[ "${lines[$outputOffset]}" =~ stackdepth=([0-9]+) ]]
    stackdepth="${BASH_REMATCH[1]}"
    case "${stackdepth}" in
    1)
      [ "${lines[$((outputOffset + 1))]}" = "# (in test file $RELATIVE_FIXTURE_ROOT/external_function_calls.bats, line $currentErrorLine)" ]
      outputOffset=$((outputOffset + 3))
      ;;
    2)
      [[ "${lines[$((outputOffset + 1))]}" =~ ^'# (from function `'.*\'' in file '.*'/test_helper.bash, line '[0-9]+,$ ]]
      [ "${lines[$((outputOffset + 2))]}" = "#  in test file $RELATIVE_FIXTURE_ROOT/external_function_calls.bats, line $currentErrorLine)" ]
      outputOffset=$((outputOffset + 4))
      ;;
    *)
      printf 'error: stackdepth=%s not implemented\n' "${stackdepth}" >&2
      return 1
      ;;
    esac
    currentErrorLine=$((currentErrorLine + linesPerTest))
  done
}

@test "test count validator catches mismatch and returns non zero" {
  # shellcheck source=lib/bats-core/validator.bash
  source "$BATS_ROOT/$BATS_LIBDIR/bats-core/validator.bash"
  export -f bats_test_count_validator
  reentrant_run bash -c "echo $'1..1\n' | bats_test_count_validator"
  [[ $status -ne 0 ]]

  reentrant_run bash -c "echo $'1..1\nok 1\nok 2' | bats_test_count_validator"
  [[ $status -ne 0 ]]

  reentrant_run bash -c "echo $'1..1\nok 1' | bats_test_count_validator"
  [[ $status -eq 0 ]]
}

@test "running the same file twice runs its tests twice without errors" {
  reentrant_run bats "$FIXTURE_ROOT/passing.bats" "$FIXTURE_ROOT/passing.bats"
  echo "$output"
  [[ $status -eq 0 ]]
  [[ "${lines[0]}" == "1..2" ]] # got 2x1 tests
}

@test "Don't use unbound variables inside bats (issue #340)" {
  reentrant_run bats "$FIXTURE_ROOT/set_-eu_in_setup_and_teardown.bats"
  echo "$output"
  [[ "${lines[0]}" == "1..4" ]]
  [[ "${lines[1]}" == "ok 1 skipped test # skip" ]]
  [[ "${lines[2]}" == "ok 2 skipped test with reason # skip reason" ]]
  [[ "${lines[3]}" == "ok 3 passing test" ]]
  [[ "${lines[4]}" == "not ok 4 failing test" ]]
  [[ "${lines[5]}" == "# (in test file $RELATIVE_FIXTURE_ROOT/set_-eu_in_setup_and_teardown.bats, line 22)" ]]
  [[ "${lines[6]}" == "#   \`false' failed" ]]
  [[ "${#lines[@]}" -eq 7 ]]
}

@test "filenames with tab can be used" {
  [[ "$OSTYPE" == "linux"* ]] || skip "FS cannot deal with tabs in filenames"

  cp "${FIXTURE_ROOT}/tab in filename.bats" "${BATS_TEST_TMPDIR}/tab"$'\t'"in filename.bats"
  bats "${BATS_TEST_TMPDIR}/tab"$'\t'"in filename.bats"
}

@test "each file is evaluated n+1 times" {
  # shellcheck disable=SC2031,SC2030
  export TEMPFILE="$BATS_TEST_TMPDIR/$BATS_TEST_NAME.log"
  reentrant_run bats "$FIXTURE_ROOT/evaluation_count/"

  cat "$TEMPFILE"

  run grep "file1" "$TEMPFILE"
  [[ ${#lines[@]} -eq 2 ]]

  run grep "file2" "$TEMPFILE"
  [[ ${#lines[@]} -eq 3 ]]
}

@test "Don't hang on CTRL-C (issue #353)" {
  if [[ "${BATS_NUMBER_OF_PARALLEL_JOBS:-1}" -gt 1 ]]; then
    skip "Aborts don't work in parallel mode"
  fi
  load 'concurrent-coordination'
  # shellcheck disable=SC2031,SC2030
  export SINGLE_USE_LATCH_DIR="${BATS_TEST_TMPDIR}"

  # guarantee that background processes get their own process group -> pid=pgid
  set -m
  bats "$FIXTURE_ROOT/hang_in_test.bats" & # don't block execution, or we cannot send signals
  SUBPROCESS_PID=$!

  single-use-latch::wait hang_in_test 1

  # emulate CTRL-C by sending SIGINT to the whole process group
  kill -SIGINT -- -$SUBPROCESS_PID

  sleep 1 # wait for the signal to be acted upon

  # when the process is gone, we cannot deliver a signal anymore, getting non-zero from kill
  run kill -0 -- -$SUBPROCESS_PID
  [[ $status -ne 0 ]] ||
    (
      kill -9 -- -$SUBPROCESS_PID
      false
    )
  #   ^ kill the process for good when SIGINT failed,
  #     to avoid waiting endlessly for stuck children to finish
}

@test "test comment style" {
  reentrant_run bats "$FIXTURE_ROOT/comment_style.bats"
  [ $status -eq 0 ]
  [ "${lines[0]}" = '1..6' ]
  [ "${lines[1]}" = 'ok 1 should_be_found' ]
  [ "${lines[2]}" = 'ok 2 should_be_found_with_trailing_whitespace' ]
  [ "${lines[3]}" = 'ok 3 should_be_found_with_parens' ]
  [ "${lines[4]}" = 'ok 4 should_be_found_with_parens_and_whitespace' ]
  [ "${lines[5]}" = 'ok 5 should_be_found_with_function_and_parens' ]
  [ "${lines[6]}" = 'ok 6 should_be_found_with_function_parens_and_whitespace' ]
}

@test "test works even if PATH is reset" {
  reentrant_run bats "$FIXTURE_ROOT/update_path_env.bats"
  [ "$status" -eq 1 ]
  [ "${lines[4]}" = "# /usr/local/bin:/usr/bin:/bin" ]
}

# bats test_tags=no-kcov
@test "Test nounset does not trip up bats' internals (see #385)" {
  # don't export nounset within this file or we might trip up the testsuite itself,
  # getting bad diagnostics
  reentrant_run bash -c "set -o nounset; export SHELLOPTS; bats --tap '$FIXTURE_ROOT/passing.bats'"
  echo "$output"
  [ "${lines[0]}" = "1..1" ]
  [ "${lines[1]}" = "ok 1 a passing test" ]
  [ ${#lines[@]} = 2 ]
}

@test "run tmpdir is cleaned up by default" {
  TEST_TMPDIR="${BATS_TEST_TMPDIR}/$BATS_TEST_NAME"
  bats --tempdir "$TEST_TMPDIR" "$FIXTURE_ROOT/passing.bats"

  [ ! -d "$TEST_TMPDIR" ]
}

@test "run tmpdir is not cleanup up with --no-cleanup-tempdir" {
  TEST_TMPDIR="${BATS_TEST_TMPDIR}/$BATS_TEST_NAME"
  bats --tempdir "$TEST_TMPDIR" --no-tempdir-cleanup "$FIXTURE_ROOT/passing.bats"

  [ -d "$TEST_TMPDIR" ]

  # should also find preprocessed files!
  [ "$(find "$TEST_TMPDIR" -name '*.src' | wc -l)" -eq 1 ]
}

@test "run should exit if tmpdir exist" {
  local dir
  dir=$(mktemp -d "${BATS_RUN_TMPDIR}/BATS_RUN_TMPDIR_TEST.XXXXXX")
  reentrant_run bats --tempdir "${dir}" "$FIXTURE_ROOT/passing.bats"
  [ "$status" -eq 1 ]
  [ "${lines[0]}" == "Error: BATS_RUN_TMPDIR (${dir}) already exists" ]
  [ "${lines[1]}" == "Reusing old run directories can lead to unexpected results ... aborting!" ]
}

@test "run should exit if TMPDIR can't be created" {
  local dir
  dir=$(mktemp "${BATS_RUN_TMPDIR}/BATS_RUN_TMPDIR_TEST.XXXXXX")
  reentrant_run bats --tempdir "${dir}" "$FIXTURE_ROOT/passing.bats"
  [ "$status" -eq 1 ]
  [ "${lines[1]}" == "Error: Failed to create BATS_RUN_TMPDIR (${dir})" ]
}

@test "Fail if BATS_TMPDIR does not exist or is not writable" {
  # shellcheck disable=SC2031,SC2030
  export TMPDIR
  TMPDIR=$(mktemp -u "${BATS_RUN_TMPDIR}/donotexist.XXXXXX")
  reentrant_run bats "$FIXTURE_ROOT/BATS_TMPDIR.bats"
  echo "$output"
  [ "$status" -eq 1 ]
  [ "${lines[0]}" = "Error: BATS_TMPDIR (${TMPDIR}) does not exist or is not a directory" ]
}

@test "Setting BATS_TMPDIR is ignored" {
  unset TMPDIR # ensure we don't have a predefined value
  expected="/tmp" reentrant_run bats "$FIXTURE_ROOT/BATS_TMPDIR.bats"
  echo "$output"
  [ "$status" -eq 0 ]
  BATS_TMPDIR="${BATS_RUN_TMPDIR}" expected="/tmp" reentrant_run bats "$FIXTURE_ROOT/BATS_TMPDIR.bats"
  [ "$status" -eq 0 ]
}

@test "Parallel mode works on MacOS with over subscription (issue #433)" {
  type -p "${BATS_PARALLEL_BINARY_NAME:-"parallel"}" &>/dev/null || skip "--jobs requires GNU parallel"
  (type -p flock &>/dev/null || type -p shlock &>/dev/null) || skip "--jobs requires flock/shlock"
  reentrant_run bats -j 2 "$FIXTURE_ROOT/issue-433"

  [ "$status" -eq 0 ]
  [[ "$output" != *"No such file or directory"* ]] || exit 1 # ensure failures are detected with old bash
}

@test "Failure in free code (see #399)" {
  reentrant_run bats --tap "$FIXTURE_ROOT/failure_in_free_code.bats"
  echo "$output"
  [ "$status" -ne 0 ]
  [ "${lines[0]}" == 1..1 ]
  [ "${lines[1]}" == 'not ok 1 setup_file failed' ]
  [ "${lines[2]}" == "# (from function \`helper' in file $RELATIVE_FIXTURE_ROOT/failure_in_free_code.bats, line 2," ]
  [ "${lines[3]}" == "#  in test file $RELATIVE_FIXTURE_ROOT/failure_in_free_code.bats, line 5)" ]
  [ "${lines[4]}" == "#   \`helper' failed" ]
}

@test "CTRL-C aborts and fails the current test" {
  if [[ "${BATS_NUMBER_OF_PARALLEL_JOBS:-1}" -gt 1 ]]; then
    skip "Aborts don't work in parallel mode"
  fi

  # shellcheck disable=SC2031,SC2030
  export TEMPFILE="$BATS_TEST_TMPDIR/$BATS_TEST_NAME.log"

  # guarantee that background processes get their own process group -> pid=pgid
  set -m

  load 'concurrent-coordination'
  # shellcheck disable=SC2031,SC2030
  export SINGLE_USE_LATCH_DIR="${BATS_SUITE_TMPDIR}"
  # we cannot use run for a background task, so we have to store the output for later
  bats "$FIXTURE_ROOT/hang_in_test.bats" --tap >"$TEMPFILE" 2>&1 & # don't block execution, or we cannot send signals

  SUBPROCESS_PID=$!

  single-use-latch::wait hang_in_test 1 10 || (
    cat "$TEMPFILE"
    false
  ) # still forward output on timeout

  # emulate CTRL-C by sending SIGINT to the whole process group
  kill -SIGINT -- -$SUBPROCESS_PID || (
    cat "$TEMPFILE"
    false
  )

  # the test suite must be marked as failed!
  wait $SUBPROCESS_PID && return 1

  run cat "$TEMPFILE"
  echo "$output"

  [ "${lines[1]}" == "not ok 1 test" ]
  # due to scheduling the exact line will vary but we should exit with 130
  [[ "${lines[2]}" == "# (in test file "*")" ]] || false
  [[ "${lines[3]}" == *"failed with status 130" ]] || false
  [ "${lines[4]}" == "# Received SIGINT, aborting ..." ]
  [ ${#lines[@]} -eq 5 ]
}

@test "CTRL-C aborts and fails the current run" {
  # shellcheck disable=SC2034
  BATS_TEST_RETRIES=2

  if [[ "${BATS_NUMBER_OF_PARALLEL_JOBS:-1}" -gt 1 ]]; then
    skip "Aborts don't work in parallel mode"
  fi

  # shellcheck disable=SC2031,2030
  export TEMPFILE="$BATS_TEST_TMPDIR/$BATS_TEST_NAME.log"

  # guarantee that background processes get their own process group -> pid=pgid
  set -m

  load 'concurrent-coordination'
  # shellcheck disable=SC2031,SC2030
  export SINGLE_USE_LATCH_DIR="${BATS_SUITE_TMPDIR}"
  # we cannot use run for a background task, so we have to store the output for later
  bats "$FIXTURE_ROOT/hang_in_run.bats" --tap >"$TEMPFILE" 2>&1 & # don't block execution, or we cannot send signals

  SUBPROCESS_PID=$!

  single-use-latch::wait hang_in_run 1 10

  # emulate CTRL-C by sending SIGINT to the whole process group
  kill -SIGINT -- -$SUBPROCESS_PID || (
    cat "$TEMPFILE"
    false
  )

  # the test suite must be marked as failed!
  wait $SUBPROCESS_PID && return 1

  run cat "$TEMPFILE"

  [ "${lines[1]}" == "not ok 1 test" ]
  # due to scheduling the exact line will vary but we should exit with 130
  [[ "${lines[3]}" == *"failed with status 130" ]] || false
  [ "${lines[4]}" == "# Received SIGINT, aborting ..." ]
}

@test "CTRL-C aborts and fails after run" {
  # shellcheck disable=SC2034
  BATS_TEST_RETRIES=2
  if [[ "${BATS_NUMBER_OF_PARALLEL_JOBS:-1}" -gt 1 ]]; then
    skip "Aborts don't work in parallel mode"
  fi

  # shellcheck disable=SC2031,2030
  export TEMPFILE="$BATS_TEST_TMPDIR/$BATS_TEST_NAME.log"

  # guarantee that background processes get their own process group -> pid=pgid
  set -m

  load 'concurrent-coordination'
  # shellcheck disable=SC2031,SC2030
  export SINGLE_USE_LATCH_DIR="${BATS_SUITE_TMPDIR}"
  # we cannot use run for a background task, so we have to store the output for later
  bats "$FIXTURE_ROOT/hang_after_run.bats" --tap >"$TEMPFILE" 2>&1 & # don't block execution, or we cannot send signals

  SUBPROCESS_PID=$!

  single-use-latch::wait hang_after_run 1 10

  # emulate CTRL-C by sending SIGINT to the whole process group
  kill -SIGINT -- -$SUBPROCESS_PID || (
    cat "$TEMPFILE"
    false
  )

  # the test suite must be marked as failed!
  wait $SUBPROCESS_PID && return 1

  run cat "$TEMPFILE"

  [ "${lines[1]}" == "not ok 1 test" ]
  # due to scheduling the exact line will vary but we should exit with 130
  [[ "${lines[3]}" == *"failed with status 130" ]] || false
  [ "${lines[4]}" == "# Received SIGINT, aborting ..." ]
}

@test "CTRL-C aborts and fails the current teardown" {
  if [[ "${BATS_NUMBER_OF_PARALLEL_JOBS:-1}" -gt 1 ]]; then
    skip "Aborts don't work in parallel mode"
  fi

  # shellcheck disable=SC2031,SC2030
  export TEMPFILE="$BATS_TEST_TMPDIR/$BATS_TEST_NAME.log"

  # guarantee that background processes get their own process group -> pid=pgid
  set -m

  load 'concurrent-coordination'
  # shellcheck disable=SC2031,SC2030
  export SINGLE_USE_LATCH_DIR="${BATS_SUITE_TMPDIR}"
  # we cannot use run for a background task, so we have to store the output for later
  bats "$FIXTURE_ROOT/hang_in_teardown.bats" --tap >"$TEMPFILE" 2>&1 & # don't block execution, or we cannot send signals

  SUBPROCESS_PID=$!

  single-use-latch::wait hang_in_teardown 1 10

  # emulate CTRL-C by sending SIGINT to the whole process group
  kill -SIGINT -- -$SUBPROCESS_PID || (
    cat "$TEMPFILE"
    false
  )

  # the test suite must be marked as failed!
  wait $SUBPROCESS_PID && return 1

  run cat "$TEMPFILE"
  echo "$output"

  [ "${lines[1]}" == "not ok 1 empty" ]
  # due to scheduling the exact line will vary but we should exit with 130
  [[ "${lines[3]}" == *"failed with status 130" ]] || false
  [ "${lines[4]}" == "# Received SIGINT, aborting ..." ]
}

@test "CTRL-C aborts and fails the current setup_file" {
  if [[ "${BATS_NUMBER_OF_PARALLEL_JOBS:-1}" -gt 1 ]]; then
    skip "Aborts don't work in parallel mode"
  fi

  # shellcheck disable=SC2031,SC2030
  export TEMPFILE="$BATS_TEST_TMPDIR/$BATS_TEST_NAME.log"

  # guarantee that background processes get their own process group -> pid=pgid
  set -m

  load 'concurrent-coordination'
  # shellcheck disable=SC2031,SC2030
  export SINGLE_USE_LATCH_DIR="${BATS_SUITE_TMPDIR}"
  # we cannot use run for a background task, so we have to store the output for later
  bats "$FIXTURE_ROOT/hang_in_setup_file.bats" --tap >"$TEMPFILE" 2>&1 & # don't block execution, or we cannot send signals

  SUBPROCESS_PID=$!

  single-use-latch::wait hang_in_setup_file 1 10

  # emulate CTRL-C by sending SIGINT to the whole process group
  kill -SIGINT -- -$SUBPROCESS_PID || (
    cat "$TEMPFILE"
    false
  )

  # the test suite must be marked as failed!
  wait $SUBPROCESS_PID && return 1

  run cat "$TEMPFILE"
  echo "$output"

  [ "${lines[1]}" == "not ok 1 setup_file failed" ]
  # due to scheduling the exact line will vary but we should exit with 130
  [[ "${lines[3]}" == *"failed with status 130" ]] || false
  [ "${lines[4]}" == "# Received SIGINT, aborting ..." ]
}

@test "CTRL-C aborts and fails the current teardown_file" {
  if [[ "${BATS_NUMBER_OF_PARALLEL_JOBS:-1}" -gt 1 ]]; then
    skip "Aborts don't work in parallel mode"
  fi
  # shellcheck disable=SC2031
  export TEMPFILE="${BATS_TEST_TMPDIR}/$BATS_TEST_NAME.log"

  # guarantee that background processes get their own process group -> pid=pgid
  set -m

  load 'concurrent-coordination'
  # shellcheck disable=SC2031
  export SINGLE_USE_LATCH_DIR="${BATS_SUITE_TMPDIR}"
  # we cannot use run for a background task, so we have to store the output for later
  bats "$FIXTURE_ROOT/hang_in_teardown_file.bats" --tap >"$TEMPFILE" 2>&1 & # don't block execution, or we cannot send signals

  SUBPROCESS_PID=$!

  single-use-latch::wait hang_in_teardown_file 1 10

  # emulate CTRL-C by sending SIGINT to the whole process group
  kill -SIGINT -- -$SUBPROCESS_PID || (
    cat "$TEMPFILE"
    false
  )

  # the test suite must be marked as failed!
  wait $SUBPROCESS_PID && return 1

  run cat "$TEMPFILE"
  echo "$output"

  [ "${lines[0]}" == "1..1" ]
  [ "${lines[1]}" == "ok 1 empty" ]
  [ "${lines[2]}" == "not ok 2 teardown_file failed" ]
  # due to scheduling the exact line will vary but we should exit with 130
  [[ "${lines[4]}" == *"failed with status 130" ]] || false
  [ "${lines[5]}" == "# Received SIGINT, aborting ..." ]
  [ "${lines[6]}" == "# bats warning: Executed 2 instead of expected 1 tests" ]
}

@test "single star in output is not treated as a glob" {
  star() { echo '*'; }

  run star
  [ "${lines[0]}" = '*' ]
}

@test "multiple stars in output are not treated as a glob" {
  stars() { echo '**'; }

  run stars
  [ "${lines[0]}" = '**' ]
}

@test "ensure all folders are shellchecked" {
  if [[ ! -f "$BATS_ROOT/shellcheck.sh" ]]; then
    skip "\$BATS_ROOT/shellcheck.sh is required for this test"
  fi
  cd "$BATS_ROOT"
  run "./shellcheck.sh" --list
  echo "$output"

  grep bin/bats <<<"$output"
  grep contrib/ <<<"$output"
  grep docker/ <<<"$output"
  grep lib/bats-core/ <<<"$output"
  grep libexec/bats-core/ <<<"$output"
  grep test/fixtures <<<"$output"
  grep install.sh <<<"$output"
}

@test "BATS_RUN_COMMAND: test content of variable" {
  run bats -v
  [[ "${BATS_RUN_COMMAND}" == "bats -v" ]]
  run bats "${BATS_TEST_DESCRIPTION}"
  echo "$BATS_RUN_COMMAND"
  [[ "$BATS_RUN_COMMAND" == "bats BATS_RUN_COMMAND: test content of variable" ]]
}

@test "--print-output-on-failure works as expected" {
  reentrant_run bats --print-output-on-failure --show-output-of-passing-tests "$FIXTURE_ROOT/print_output_on_failure.bats"
  [ "${lines[0]}" == '1..3' ]
  [ "${lines[1]}" == 'ok 1 no failure prints no output' ]
  # ^ no output despite --show-output-of-passing-tests, because there is no failure
  [ "${lines[2]}" == 'not ok 2 failure prints output' ]
  [ "${lines[3]}" == "# (in test file $RELATIVE_FIXTURE_ROOT/print_output_on_failure.bats, line 7)" ]
  [ "${lines[4]}" == "#   \`false' failed" ]
  [ "${lines[5]}" == '# Last output:' ]
  [ "${lines[6]}" == '# fail hard' ]
  [ "${lines[7]}" == 'not ok 3 empty output on failure' ]
  [ "${lines[8]}" == "# (in test file $RELATIVE_FIXTURE_ROOT/print_output_on_failure.bats, line 11)" ]
  [ "${lines[9]}" == "#   \`false' failed" ]
  [ ${#lines[@]} -eq 10 ]
}

@test "--print-output-on-failure also shows stderr (for run --separate-stderr)" {
  reentrant_run bats --print-output-on-failure --show-output-of-passing-tests "$FIXTURE_ROOT/print_output_on_failure_with_stderr.bats"
  [ "${lines[0]}" == '1..3' ]
  [ "${lines[1]}" == 'ok 1 no failure prints no output' ]
  # ^ no output despite --show-output-of-passing-tests, because there is no failure
  [ "${lines[2]}" == 'not ok 2 failure prints output' ]
  [ "${lines[3]}" == "# (in test file $RELATIVE_FIXTURE_ROOT/print_output_on_failure_with_stderr.bats, line 8)" ]
  [ "${lines[4]}" == "#   \`false' failed" ]
  [ "${lines[5]}" == '# Last output:' ]
  [ "${lines[6]}" == '# fail hard' ]
  [ "${lines[7]}" == '# Last stderr:' ]
  [ "${lines[8]}" == '# with stderr' ]
  [ "${lines[9]}" == 'not ok 3 empty output on failure' ]
  [ "${lines[10]}" == "# (in test file $RELATIVE_FIXTURE_ROOT/print_output_on_failure_with_stderr.bats, line 12)" ]
  [ "${lines[11]}" == "#   \`false' failed" ]
  [ ${#lines[@]} -eq 12 ]
}

@test "--show-output-of-passing-tests works as expected" {
  bats_require_minimum_version 1.5.0
  reentrant_run -0 bats --show-output-of-passing-tests "$FIXTURE_ROOT/show-output-of-passing-tests.bats"
  [ "${lines[0]}" == '1..1' ]
  [ "${lines[1]}" == 'ok 1 test' ]
  [ "${lines[2]}" == '# output' ]
  [ ${#lines[@]} -eq 3 ]
}

@test "--verbose-run prints output" {
  bats_require_minimum_version 1.5.0
  reentrant_run -1 bats --verbose-run "$FIXTURE_ROOT/verbose-run.bats"
  [ "${lines[0]}" == '1..1' ]
  [ "${lines[1]}" == 'not ok 1 test' ]
  [ "${lines[2]}" == "# (in test file $RELATIVE_FIXTURE_ROOT/verbose-run.bats, line 3)" ]
  [ "${lines[3]}" == "#   \`run ! echo test' failed, expected nonzero exit code!" ]
  [ "${lines[4]}" == '# test' ]
  [ ${#lines[@]} -eq 5 ]
}

@test "BATS_VERBOSE_RUN=1 also prints output" {
  bats_require_minimum_version 1.5.0
  reentrant_run -1 env BATS_VERBOSE_RUN=1 bats "$FIXTURE_ROOT/verbose-run.bats"
  [ "${lines[0]}" == '1..1' ]
  [ "${lines[1]}" == 'not ok 1 test' ]
  [ "${lines[2]}" == "# (in test file $RELATIVE_FIXTURE_ROOT/verbose-run.bats, line 3)" ]
  [ "${lines[3]}" == "#   \`run ! echo test' failed, expected nonzero exit code!" ]
  [ "${lines[4]}" == '# test' ]
  [ ${#lines[@]} -eq 5 ]
}

@test "--gather-test-outputs-in gathers outputs of all tests (even succeeding!)" {
  local OUTPUT_DIR="$BATS_TEST_TMPDIR/logs"
  reentrant_run bats --verbose-run --gather-test-outputs-in "$OUTPUT_DIR" "$FIXTURE_ROOT/print_output_on_failure.bats"

  [ -d "$OUTPUT_DIR" ] # will be generated!

  # even outputs of successful tests are generated
  OUTPUT=$(<"$OUTPUT_DIR/1-no failure prints no output.log") # own line to trigger failure if file does not exist
  [ "$OUTPUT" == "success" ]

  OUTPUT=$(<"$OUTPUT_DIR/2-failure prints output.log")
  [ "$OUTPUT" == "fail hard" ]

  # even empty outputs are generated
  OUTPUT=$(<"$OUTPUT_DIR/3-empty output on failure.log")
  [ "$OUTPUT" == "" ]

  [ "$(find "$OUTPUT_DIR" -type f | wc -l)" -eq 3 ]
}

@test "--gather-test-outputs-in allows directory to exist (only if empty)" {
  local OUTPUT_DIR="$BATS_TEST_TMPDIR/logs"
  bats_require_minimum_version 1.5.0

  # anything existing, even if empty, 'hidden', etc. should cause failure
  mkdir "$OUTPUT_DIR" && touch "$OUTPUT_DIR/.oops"
  reentrant_run -1 bats --verbose-run --gather-test-outputs-in "$OUTPUT_DIR" "$FIXTURE_ROOT/passing.bats"
  [ "${lines[0]}" == "Error: Directory '$OUTPUT_DIR' must be empty for --gather-test-outputs-in" ]

  # empty directory is just fine
  rm "$OUTPUT_DIR/.oops" && rmdir "$OUTPUT_DIR" # avoiding rm -fr to avoid goofs
  mkdir "$OUTPUT_DIR"
  reentrant_run -0 bats --verbose-run --gather-test-outputs-in "$OUTPUT_DIR" "$FIXTURE_ROOT/passing.bats"
  [ "$(find "$OUTPUT_DIR" -type f | wc -l)" -eq 1 ]
}

@test "--gather-test-output-in works with slashes in test names" {
  local OUTPUT_DIR="$BATS_TEST_TMPDIR/logs"
  bats_require_minimum_version 1.5.0

  reentrant_run -0 bats --gather-test-outputs-in "$OUTPUT_DIR" "$FIXTURE_ROOT/test_with_slash.bats"
  [ -e "$OUTPUT_DIR/1-test with %2F in name.log" ]
}

@test "Tell about missing flock and shlock" {
  if ! command -v parallel; then
    skip "this test requires GNU parallel to be installed"
  fi
  if command -v flock; then
    skip "this test requires flock not to be installed"
  fi
  if command -v shlock; then
    skip "this test requires flock not to be installed"
  fi

  bats_require_minimum_version 1.5.0
  reentrant_run ! bats --jobs 2 "$FIXTURE_ROOT/parallel.bats"
  [ "${lines[0]}" == "ERROR: flock/shlock is required for parallelization within files!" ]
  [ "${#lines[@]}" -eq 1 ]
}

@test "Test with a name that is waaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaay too long" {
  skip "This test should only check if the long name chokes bats' internals during execution"
}

@test "BATS_CODE_QUOTE_STYLE works with any two characters (even unicode)" {
  bats_require_minimum_version 1.5.0

  # shellcheck disable=SC2030,SC2031
  REENTRANT_RUN_PRESERVE+=(BATS_CODE_QUOTE_STYLE)
  BATS_CODE_QUOTE_STYLE='``' reentrant_run -1 bats --tap "${FIXTURE_ROOT}/failing.bats"
  # shellcheck disable=SC2016
  [ "${lines[3]}" == '#   `eval "( exit ${STATUS:-1} )"` failed' ]

  export BATS_CODE_QUOTE_STYLE='😁😂'
  if [[ ${#BATS_CODE_QUOTE_STYLE} -ne 2 ]]; then
    # for example, this happens on windows!
    skip 'Unicode chars are not counted as one char in this system'
  fi

  bats_require_minimum_version 1.5.0
  reentrant_run -1 bats --tap "${FIXTURE_ROOT}/failing.bats"
  # shellcheck disable=SC2016
  [ "${lines[3]}" == '#   😁eval "( exit ${STATUS:-1} )"😂 failed' ]
}

@test "BATS_CODE_QUOTE_STYLE=custom requires BATS_CODE_QUOTE_BEGIN/END" {
  # unset because they are set in the surrounding scope
  unset BATS_BEGIN_CODE_QUOTE BATS_END_CODE_QUOTE

  bats_require_minimum_version 1.5.0

  # shellcheck disable=SC2030,SC2031
  REENTRANT_RUN_PRESERVE+=(BATS_CODE_QUOTE_STYLE)
  BATS_CODE_QUOTE_STYLE=custom reentrant_run -1 bats --tap "${FIXTURE_ROOT}/passing.bats"
  [ "${lines[0]}" == 'ERROR: BATS_CODE_QUOTE_STYLE=custom requires BATS_BEGIN_CODE_QUOTE and BATS_END_CODE_QUOTE to be set' ]

  REENTRANT_RUN_PRESERVE+=(BATS_BEGIN_CODE_QUOTE BATS_END_CODE_QUOTE)
  # shellcheck disable=SC2016
  BATS_CODE_QUOTE_STYLE=custom \
    BATS_BEGIN_CODE_QUOTE='$(' \
    BATS_END_CODE_QUOTE=')' \
    reentrant_run -1 bats --tap "${FIXTURE_ROOT}/failing.bats"
  # shellcheck disable=SC2016
  [ "${lines[3]}" == '#   $(eval "( exit ${STATUS:-1} )") failed' ]
}

@test "Warn about invalid BATS_CODE_QUOTE_STYLE" {
  bats_require_minimum_version 1.5.0

  # shellcheck disable=SC2030,SC2031
  REENTRANT_RUN_PRESERVE+=(BATS_CODE_QUOTE_STYLE)

  BATS_CODE_QUOTE_STYLE='' reentrant_run -1 bats --tap "${FIXTURE_ROOT}/passing.bats"
  [ "${lines[0]}" == 'ERROR: Unknown BATS_CODE_QUOTE_STYLE: ' ]

  BATS_CODE_QUOTE_STYLE='1' reentrant_run -1 bats --tap "${FIXTURE_ROOT}/passing.bats"
  [ "${lines[0]}" == 'ERROR: Unknown BATS_CODE_QUOTE_STYLE: 1' ]

  BATS_CODE_QUOTE_STYLE='three' reentrant_run -1 bats --tap "${FIXTURE_ROOT}/passing.bats"
  [ "${lines[0]}" == 'ERROR: Unknown BATS_CODE_QUOTE_STYLE: three' ]
}

@test "Debug trap must only override variables that are prefixed with BATS_ (issue #519)" {
  # use declare -p to gather variables in pristine bash and bats @test environment
  # then compare which ones are introduced in @test compared to bash

  # make declare's output more readable and suitable for `comm`
  if [[ "${BASH_VERSINFO[0]}" -eq 3 ]]; then
    normalize_variable_list() {
      # `declare -p`: VAR_NAME="VALUE"
      # will also contain function definitions!
      while read -r line; do
        # Skip variable assignments in function definitions!
        # (They will be indented.)
        declare_regex='^declare -[^[:space:]]+ ([^=]+)='
        plain_regex='^([^=[:space]]+)='
        if [[ $line =~ $declare_regex ]]; then
          printf "%s\n" "${BASH_REMATCH[1]}"
        elif [[ $line =~ $plain_regex ]]; then
          printf "%s\n" "${BASH_REMATCH[1]}"
        fi
      done | sort
    }
  else
    normalize_variable_list() {
      # `declare -p`: declare -X VAR_NAME="VALUE"
      while IFS=' =' read -r _declare _ variable _; do
        if [[ "$_declare" == declare ]]; then # skip multiline variables' values
          printf "%s\n" "$variable"
        fi
      done | sort
    }
  fi

  # get the bash baseline
  # add variables that should be ignored like PIPESTATUS here
  BASH_DECLARED_VARIABLES=$(env -i PIPESTATUS= "$BASH" -c "declare -p")
  local BATS_DECLARED_VARIABLES_FILE="${BATS_TEST_TMPDIR}/variables.log"
  bats_require_minimum_version 1.5.0
  # now capture bats @test environment
  reentrant_run -0 env -i PATH="$PATH" BATS_DECLARED_VARIABLES_FILE="$BATS_DECLARED_VARIABLES_FILE" bash "${BATS_ROOT}/bin/bats" "${FIXTURE_ROOT}/issue-519.bats"
  # use function to allow failing via !, run is a bit unwieldy with the pipe and subshells
  check_no_new_variables() {
    # -23 -> only look at additions on the bats list
    ! comm -23 <(normalize_variable_list <"$BATS_DECLARED_VARIABLES_FILE") \
      <(normalize_variable_list <<<"$BASH_DECLARED_VARIABLES") |
      grep -v '^BATS_' # variables that are prefixed with BATS_ don't count
  }
  check_no_new_variables
}

@test "Don't wait for disowned background jobs to finish because of open FDs (#205)" {
  SECONDS=0
  export LOG_FILE="$BATS_TEST_TMPDIR/fds.log"
  bats_require_minimum_version 1.5.0
  reentrant_run -0 bats --show-output-of-passing-tests --tap "${FIXTURE_ROOT}/issue-205.bats"
  echo "Whole suite took: $SECONDS seconds"
  FDS_LOG=$(<"$LOG_FILE")
  echo "$FDS_LOG"
  [ $SECONDS -lt 10 ]
  [[ $FDS_LOG == *'otherfunc fds after: (0 1 2)'* ]] || false
  [[ $FDS_LOG == *'setup_file fds after: (0 1 2)'* ]] || false
}

@test "Allow for prefixing tests' names with BATS_TEST_NAME_PREFIX" {
  # shellcheck disable=SC2030,SC2031
  REENTRANT_RUN_PRESERVE+=(BATS_TEST_NAME_PREFIX)
  BATS_TEST_NAME_PREFIX='PREFIX: ' reentrant_run bats "${FIXTURE_ROOT}/passing.bats"
  [ "${lines[1]}" == "ok 1 PREFIX: a passing test" ]
}

@test "Setting status in teardown* does not override exit code (see issue #575)" {
  bats_require_minimum_version 1.5.0
  TEARDOWN_RETURN_CODE=0 TEST_RETURN_CODE=0 STATUS=0 reentrant_run -0 bats "$FIXTURE_ROOT/teardown_override_status.bats"
  TEARDOWN_RETURN_CODE=1 TEST_RETURN_CODE=0 STATUS=0 reentrant_run -1 bats "$FIXTURE_ROOT/teardown_override_status.bats"
  TEARDOWN_RETURN_CODE=0 TEST_RETURN_CODE=1 STATUS=0 reentrant_run -1 bats "$FIXTURE_ROOT/teardown_override_status.bats"
  TEARDOWN_RETURN_CODE=1 TEST_RETURN_CODE=1 STATUS=0 reentrant_run -1 bats "$FIXTURE_ROOT/teardown_override_status.bats"
  TEARDOWN_RETURN_CODE=0 TEST_RETURN_CODE=0 STATUS=1 reentrant_run -0 bats "$FIXTURE_ROOT/teardown_override_status.bats"
  TEARDOWN_RETURN_CODE=1 TEST_RETURN_CODE=0 STATUS=1 reentrant_run -1 bats "$FIXTURE_ROOT/teardown_override_status.bats"

  TEARDOWN_RETURN_CODE=0 TEST_RETURN_CODE=0 STATUS=0 reentrant_run -0 bats "$FIXTURE_ROOT/teardown_file_override_status.bats"
  TEARDOWN_RETURN_CODE=1 TEST_RETURN_CODE=0 STATUS=0 reentrant_run -1 bats "$FIXTURE_ROOT/teardown_file_override_status.bats"
  TEARDOWN_RETURN_CODE=0 TEST_RETURN_CODE=1 STATUS=0 reentrant_run -1 bats "$FIXTURE_ROOT/teardown_file_override_status.bats"
  TEARDOWN_RETURN_CODE=1 TEST_RETURN_CODE=1 STATUS=0 reentrant_run -1 bats "$FIXTURE_ROOT/teardown_file_override_status.bats"
  TEARDOWN_RETURN_CODE=0 TEST_RETURN_CODE=0 STATUS=1 reentrant_run -0 bats "$FIXTURE_ROOT/teardown_file_override_status.bats"
  TEARDOWN_RETURN_CODE=1 TEST_RETURN_CODE=0 STATUS=1 reentrant_run -1 bats "$FIXTURE_ROOT/teardown_file_override_status.bats"

  TEARDOWN_RETURN_CODE=0 TEST_RETURN_CODE=0 STATUS=0 reentrant_run -0 bats "$FIXTURE_ROOT/teardown_suite_override_status/"
  TEARDOWN_RETURN_CODE=1 TEST_RETURN_CODE=0 STATUS=0 reentrant_run -1 bats "$FIXTURE_ROOT/teardown_suite_override_status/"
  TEARDOWN_RETURN_CODE=0 TEST_RETURN_CODE=1 STATUS=0 reentrant_run -1 bats "$FIXTURE_ROOT/teardown_suite_override_status/"
  TEARDOWN_RETURN_CODE=1 TEST_RETURN_CODE=1 STATUS=0 reentrant_run -1 bats "$FIXTURE_ROOT/teardown_suite_override_status/"
  TEARDOWN_RETURN_CODE=0 TEST_RETURN_CODE=0 STATUS=1 reentrant_run -0 bats "$FIXTURE_ROOT/teardown_suite_override_status/"
  TEARDOWN_RETURN_CODE=1 TEST_RETURN_CODE=0 STATUS=1 reentrant_run -1 bats "$FIXTURE_ROOT/teardown_suite_override_status/"
}

@test "BATS_* variables don't contain double slashes" {
  TMPDIR=/tmp/ bats "$FIXTURE_ROOT/BATS_variables_dont_contain_double_slashes.bats"
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
  reentrant_run -1 bats --filter-status failed "many_passing_and_one_failing.bats"
  # without previous recording, all tests should be run
  [ "${lines[0]}" == 'No recording of previous runs found. Running all tests!' ]
  [ "${lines[1]}" == '1..4' ]
  [ "$(grep -c 'not ok' <<<"$output")" -eq 1 ]

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
  [ "${lines[0]}" == "There where no failed tests in the last recorded run." ]
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

@test "BATS_TEST_RETRIES allows for retrying tests" {
  # shellcheck disable=SC2030
  export LOG="$BATS_TEST_TMPDIR/call.log"
  bats_require_minimum_version 1.5.0
  reentrant_run ! bats "$FIXTURE_ROOT/retry.bats"
  [ "${lines[0]}" == '1..3' ]
  [ "${lines[1]}" == 'not ok 1 Fail all' ]
  [ "${lines[4]}" == 'ok 2 Fail once' ]
  [ "${lines[5]}" == 'not ok 3 Override retries' ]

  run cat "$LOG"
  [ "${lines[0]}" == ' setup_file ' ]     # should only be executed once
  [ "${lines[22]}" == ' teardown_file ' ] # should only be executed once
  [ "${#lines[@]}" -eq 23 ]

  # 3x Fail All (give up after 3 tries/2 retries)
  run grep test_Fail_all <"$LOG"
  [ "${lines[0]}" == 'test_Fail_all setup 1' ] # should be executed for each try
  [ "${lines[1]}" == 'test_Fail_all test_Fail_all 1' ]
  [ "${lines[2]}" == 'test_Fail_all teardown 1' ] # should be executed for each try
  [ "${lines[3]}" == 'test_Fail_all setup 2' ]
  [ "${lines[4]}" == 'test_Fail_all test_Fail_all 2' ]
  [ "${lines[5]}" == 'test_Fail_all teardown 2' ]
  [ "${lines[6]}" == 'test_Fail_all setup 3' ]
  [ "${lines[7]}" == 'test_Fail_all test_Fail_all 3' ]
  [ "${lines[8]}" == 'test_Fail_all teardown 3' ]
  [ "${#lines[@]}" -eq 9 ]

  # 2x Fail once (pass second try/first retry)
  run grep test_Fail_once <"$LOG"
  [ "${lines[0]}" == 'test_Fail_once setup 1' ]
  [ "${lines[1]}" == 'test_Fail_once test_Fail_once 1' ]
  [ "${lines[2]}" == 'test_Fail_once teardown 1' ]
  [ "${lines[3]}" == 'test_Fail_once setup 2' ]
  [ "${lines[4]}" == 'test_Fail_once test_Fail_once 2' ]
  [ "${lines[5]}" == 'test_Fail_once teardown 2' ]
  [ "${#lines[@]}" -eq 6 ]

  # 2x Override retries (give up after second try/first retry)
  run grep test_Override_retries <"$LOG"
  [ "${lines[0]}" == 'test_Override_retries setup 1' ]
  [ "${lines[1]}" == 'test_Override_retries test_Override_retries 1' ]
  [ "${lines[2]}" == 'test_Override_retries teardown 1' ]
  [ "${lines[3]}" == 'test_Override_retries setup 2' ]
  [ "${lines[4]}" == 'test_Override_retries test_Override_retries 2' ]
  [ "${lines[5]}" == 'test_Override_retries teardown 2' ]
  [ "${#lines[@]}" -eq 6 ]

}

@test "Exit code is zero after successful retry (see #660)" {
  # shellcheck disable=SC2031
  export LOG="$BATS_TEST_TMPDIR/call.log"
  bats_require_minimum_version 1.5.0
  reentrant_run -0 bats "$FIXTURE_ROOT/retry_success.bats"
  [ "${lines[0]}" == '1..1' ]
  [ "${lines[1]}" == 'ok 1 Fail once' ]
  [ ${#lines[@]} == 2 ]
}

@test "Error on invalid --line-reference-format" {
  bats_require_minimum_version 1.5.0

  reentrant_run -1 bats --line-reference-format invalid "$FIXTURE_ROOT/passing.bats"
  [ "${lines[0]}" == "Error: Invalid BATS_LINE_REFERENCE_FORMAT 'invalid' (e.g. via --line-reference-format)" ]
}

@test "--line-reference-format switches format" {
  bats_require_minimum_version 1.5.0

  reentrant_run -1 bats --line-reference-format colon "$FIXTURE_ROOT/failing.bats"
  [ "${lines[2]}" == "# (in test file $RELATIVE_FIXTURE_ROOT/failing.bats:4)" ]

  reentrant_run -1 bats --line-reference-format uri "$FIXTURE_ROOT/failing.bats"
  [ "${lines[2]}" == "# (in test file file://$FIXTURE_ROOT/failing.bats:4)" ]

  bats_format_file_line_reference_custom() {
    printf -v "$output" "%s<-%d" "$1" "$2"
  }
  export -f bats_format_file_line_reference_custom
  reentrant_run -1 bats --line-reference-format custom "$FIXTURE_ROOT/failing.bats"
  [ "${lines[2]}" == "# (in test file $RELATIVE_FIXTURE_ROOT/failing.bats<-4)" ]
}

@test "Focus tests filter out other tests and override exit code" {
  bats_require_minimum_version 1.5.0
  # expect exit 1: focus mode always fails tests
  reentrant_run -1 bats "$FIXTURE_ROOT/focus.bats"
  [ "${lines[0]}" == "WARNING: This test run only contains tests tagged \`bats:focus\`!" ]
  [ "${lines[1]}" == '1..1' ]
  [ "${lines[2]}" == 'ok 1 focused' ]
  [ "${lines[3]}" == "Marking test run as failed due to \`bats:focus\` tag. (Set \`BATS_NO_FAIL_FOCUS_RUN=1\` to disable.)" ]
  [ "${#lines[@]}" == 4 ]
}

@test "Focus tests with BATS_NO_FAIL_FOCUS_RUN=1 does not override exit code" {
  bats_require_minimum_version 1.5.0
  # shellcheck disable=SC2031
  REENTRANT_RUN_PRESERVE+=(BATS_NO_FAIL_FOCUS_RUN)
  BATS_NO_FAIL_FOCUS_RUN=1 reentrant_run -0 bats "$FIXTURE_ROOT/focus.bats"
  [ "${lines[0]}" == "WARNING: This test run only contains tests tagged \`bats:focus\`!" ]
  [ "${lines[1]}" == '1..1' ]
  [ "${lines[2]}" == 'ok 1 focused' ]
  [ "${lines[3]}" == "WARNING: This test run only contains tests tagged \`bats:focus\`!" ]
  [ "${#lines[@]}" == 4 ]
}

@test "Bats waits for report formatter to finish" {
  REPORT_FORMATTER=$FIXTURE_ROOT/gobble_up_stdin_sleep_and_print_finish.bash
  bats_require_minimum_version 1.5.0
  reentrant_run -0 bats "$FIXTURE_ROOT/passing.bats" --report-formatter "$REPORT_FORMATTER" --output "$BATS_TEST_TMPDIR"

  echo "'$(< "$BATS_TEST_TMPDIR/report.log")'"
  [ "$(< "$BATS_TEST_TMPDIR/report.log")" = Finished ]
}

@test "Failing report formatter fails test run" {
  REPORT_FORMATTER=$FIXTURE_ROOT/exit_11.bash
  bats_require_minimum_version 1.5.0
  reentrant_run ! bats "$FIXTURE_ROOT/passing.bats" --report-formatter "$REPORT_FORMATTER" --output "$BATS_TEST_TMPDIR"

  [[ "${output}" = *"ERROR: command \`$REPORT_FORMATTER\` failed with status 11"* ]] || false
}

@test "Short opt unpacker rejects valued options" {
  bats_require_minimum_version 1.5.0
  reentrant_run ! bats "$FIXTURE_ROOT/passing.bats" -Fr tap
  [[ "${output}" == *"Error: -F is not allowed within pack of flags."* ]] || false

  reentrant_run -0 bats "$FIXTURE_ROOT/passing.bats" -rF tap
}

@test "Test timing does not break when overriding date on path" {
  bats "$FIXTURE_ROOT/override_date_on_path.bats"
}