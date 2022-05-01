load test_helper
fixtures suite_setup_teardown

setup() {
    export LOGFILE="$BATS_TEST_TMPDIR/log"
}

@test "setup_suite.bash is picked up in toplevel folder of suite" {
    run -0 bats "$FIXTURE_ROOT/pick_up_toplevel"
    run cat "$LOGFILE"

    [ "${lines[0]}" = "$FIXTURE_ROOT/pick_up_toplevel/setup_suite.bash setup_suite" ]
    [ "${lines[1]}" = "$FIXTURE_ROOT/pick_up_toplevel/setup_suite.bash teardown_suite" ]
}

@test "setup_suite.bash is picked up in folder of first test file" {
    run -0 bats "$FIXTURE_ROOT/pick_up_toplevel/folder1/test.bats" "$FIXTURE_ROOT/pick_up_toplevel/test.bats"
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