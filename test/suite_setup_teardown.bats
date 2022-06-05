load test_helper
fixtures suite_setup_teardown
bats_require_minimum_version 1.5.0

setup() {
    export LOGFILE="$BATS_TEST_TMPDIR/log"
}

@test "setup_suite.bash is picked up in toplevel folder of suite" {
    run -0 bats -r "$FIXTURE_ROOT/pick_up_toplevel"
    run cat "$LOGFILE"

    [ "${lines[0]}" = "$FIXTURE_ROOT/pick_up_toplevel/setup_suite.bash setup_suite" ]
    [ "${lines[1]}" = "$FIXTURE_ROOT/pick_up_toplevel/setup_suite.bash teardown_suite" ]
}

@test "setup_suite.bash is picked up in folder of first test file" {
    run -0 bats "$FIXTURE_ROOT/pick_up_toplevel/folder1/test.bats" "$FIXTURE_ROOT/pick_up_toplevel/folder2/test.bats"
    run cat "$LOGFILE"

    [ "${lines[0]}" = "$FIXTURE_ROOT/pick_up_toplevel/folder1/setup_suite.bash setup_suite" ]
    [ "${lines[1]}" = "$FIXTURE_ROOT/pick_up_toplevel/folder1/setup_suite.bash teardown_suite" ]
}

@test "setup_suite is not picked up from wrongly named file" {
    run -0 bats "$FIXTURE_ROOT/non_default_name/"
    run cat "$LOGFILE"
    [[ "${output}" != *"setup_suite"* ]] || false
    [[ "${output}" != *"teardown_suite"* ]] || false
}

@test "setup_suite is picked up from --setup-suite-file" {
    run -0 bats "$FIXTURE_ROOT/non_default_name/" \
                --setup-suite-file "$FIXTURE_ROOT/non_default_name/setup_suite_non_default.bash"
    run cat "$LOGFILE"
    [ "${lines[0]}" == "setup_suite non_default" ]
    [ "${lines[1]}" == "teardown_suite non_default" ]
}

@test "--setup-suite-file takes precedence over convention" {
    run -0 bats "$FIXTURE_ROOT/default_name/" \
                --setup-suite-file "$FIXTURE_ROOT/non_default_name/setup_suite_non_default.bash"
    run cat "$LOGFILE"
    [ "${lines[0]}" == "setup_suite non_default" ]
    [ "${lines[1]}" == "teardown_suite non_default" ]
}

@test "passing a nonexisting file to --setup-suite-file prints an error message" {
    run -1 bats "$FIXTURE_ROOT/default_name/" \
                --setup-suite-file "/non-existing/setup_suite.bash"
    [ "${lines[0]}" == "Error: --setup-suite-file /non-existing/setup_suite.bash does not exist!" ]
}

@test "setup_suite.bash without setup_suite() is an error" {
    run ! bats "$FIXTURE_ROOT/no_setup_suite_function/"
    [ "${lines[1]}" == "$FIXTURE_ROOT/no_setup_suite_function/setup_suite.bash does not define \`setup_suite()\`" ]
}

@test "exported variables from setup_suite are visible in setup_file, setup and @test" {
    unset EXPORTED_VAR
    EXPECTED_VALUE=exported_var run -0 bats "$FIXTURE_ROOT/exported_vars/"
}

@test "syntax errors in setup_suite.bash are reported and lead to non zero exit code" {
    LANG=C run ! bats --setup-suite-file "$FIXTURE_ROOT/syntax_error/setup_suite_no_shellcheck" "$FIXTURE_ROOT/syntax_error/"
    [ "${lines[1]}" == "$FIXTURE_ROOT/syntax_error/setup_suite_no_shellcheck: line 2: syntax error: unexpected end of file" ]
}

@test "errors in setup_suite.bash's free code reported correctly" {
    LANG=C run ! bats "$FIXTURE_ROOT/error_in_free_code/"
    [ "${lines[1]}" == "$FIXTURE_ROOT/error_in_free_code/setup_suite.bash: line 1: call-to-undefined-command: command not found" ]
}

@test "errors in setup_suite reported correctly" {
    LANG=C run ! bats "$FIXTURE_ROOT/error_in_setup_suite/"
    [ "${lines[1]}" == "$FIXTURE_ROOT/error_in_setup_suite/setup_suite.bash: line 2: call-to-undefined-command: command not found" ]
}

@test "errors in teardown_suite reported correctly" {
    LANG=C run ! bats "$FIXTURE_ROOT/error_in_teardown_suite/"
    [ "${lines[2]}" == "$FIXTURE_ROOT/error_in_teardown_suite/setup_suite.bash: line 6: call-to-undefined-command: command not found" ]
}

@test "failure in setup_suite skips further setup and suite but runs teardown_suite" {
    run ! bats "$FIXTURE_ROOT/failure_in_setup_suite/"
    [ "${lines[1]}" == "setup_suite before" ] # <- only setup_suite code before failure is run
    [ "${lines[2]}" == "teardown_suite" ] # <- teardown is run
    # get a nice error message
    [ "${lines[3]}" == "not ok 1 setup_suite" ]
    [ "${lines[4]}" == "# (from function \`setup_suite' in test file $RELATIVE_FIXTURE_ROOT/failure_in_setup_suite/setup_suite.bash, line 3)" ]
    [ "${lines[5]}" == "#   \`false' failed" ]
}

@test "failure in teardown_suite is reported and fails test suite, remaining code is skipped" {
    run ! bats "$FIXTURE_ROOT/failure_in_teardown_suite/"
    [ "${lines[2]}" == "teardown_suite before" ]
    [ "${lines[3]}" == "not ok 2 teardown_suite" ]
    [ "${lines[4]}" == "# (from function \`teardown_suite' in test file $RELATIVE_FIXTURE_ROOT/failure_in_teardown_suite/setup_suite.bash, line 7)" ]
    [ "${lines[5]}" == "#   \`false' failed" ]
}

@test "stderr from setup/teardown_suite does not overtake stdout" {
    run -0 --separate-stderr bats "$FIXTURE_ROOT/stderr_in_setup_teardown_suite/"
    [[ "$output" == *$'setup_suite stdout\nsetup_suite stderr'* ]] || false
    [[ "$output" == *$'teardown_suite stdout\nteardown_suite stderr'* ]] || false
}