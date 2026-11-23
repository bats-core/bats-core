setup() {
  load test_helper
  fixtures suite
  REENTRANT_RUN_PRESERVE+=(BATS_LIBEXEC)
}

@test "Empty suite is an error" {
  bats_require_minimum_version 1.5.0
  reentrant_run --separate-stderr -1 bats "$FIXTURE_ROOT/empty"
  [ "$output" = "1..0" ]
  # shellcheck disable=SC2154
  [ "$stderr" = "ERROR: Found no tests. Use \`--allow-empty-suite\` or \`BATS_ALLOW_EMPTY_SUITE=1\` to suppress this error." ]
}

@test "running a suite with one test file" {
  reentrant_run bats "$FIXTURE_ROOT/single"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..1" ]
  [ "${lines[1]}" = "ok 1 a passing test" ]
}

@test "running a suite containing only a hidden test file" {
  printf '@test "hidden test" { true; }\n' >"$BATS_TEST_TMPDIR/.hidden.bats"

  reentrant_run bats "$BATS_TEST_TMPDIR"
  [[ "$status" -eq 0 ]]
  [[ "${lines[0]}" = '1..1' ]]
  [[ "${lines[1]}" = 'ok 1 hidden test' ]]
}

@test "directory discovery includes hidden test files without recursing" {
  local filename
  for filename in .bats '..hidden.bats' '.hidden with spaces.bats' visible.bats; do
    printf '@test "%s" { true; }\n' "$filename" >"$BATS_TEST_TMPDIR/$filename"
  done
  mkdir "$BATS_TEST_TMPDIR/.hidden-directory"
  printf '@test "nested" { true; }\n' >"$BATS_TEST_TMPDIR/.hidden-directory/nested.bats"
  mkdir "$BATS_TEST_TMPDIR/.hidden-directory.bats" "$BATS_TEST_TMPDIR/visible-directory.bats"

  reentrant_run bats "$BATS_TEST_TMPDIR"
  [[ "$status" -eq 0 ]]
  [[ "${lines[0]}" = '1..4' ]]
  [[ "$output" == *' .bats'* ]]
  [[ "$output" == *' ..hidden.bats'* ]]
  [[ "$output" == *' .hidden with spaces.bats'* ]]
  [[ "$output" == *' visible.bats'* ]]
  [[ "$output" != *nested* ]]
}

@test "recursive discovery includes hidden test files and directories" {
  mkdir "$BATS_TEST_TMPDIR/.hidden-directory"
  printf '@test "hidden root" { true; }\n' >"$BATS_TEST_TMPDIR/.hidden.bats"
  printf '@test "hidden nested" { true; }\n' >"$BATS_TEST_TMPDIR/.hidden-directory/.nested.bats"

  reentrant_run bats -r "$BATS_TEST_TMPDIR"
  [[ "$status" -eq 0 ]]
  [[ "${lines[0]}" = '1..2' ]]
  [[ "$output" == *' hidden root'* ]]
  [[ "$output" == *' hidden nested'* ]]
}

@test "hidden test files honor BATS_FILE_EXTENSION" {
  printf '@test "hidden custom" { true; }\n' >"$BATS_TEST_TMPDIR/.hidden.test"
  printf '@test "default extension" { false; }\n' >"$BATS_TEST_TMPDIR/.hidden.bats"

  reentrant_run env BATS_FILE_EXTENSION=test bats "$BATS_TEST_TMPDIR"
  [[ "$status" -eq 0 ]]
  [[ "${lines[0]}" = '1..1' ]]
  [[ "${lines[1]}" = 'ok 1 hidden custom' ]]
}

@test "directory discovery preserves disabled dotglob for tests" {
  printf '@test "dotglob stays disabled" { ! shopt -q dotglob; }\n' >"$BATS_TEST_TMPDIR/options.bats"

  reentrant_run env BASHOPTS= bats "$BATS_TEST_TMPDIR"
  [[ "$status" -eq 0 ]]
  [[ "${lines[1]}" = 'ok 1 dotglob stays disabled' ]]
}

@test "directory discovery preserves enabled dotglob for tests" {
  if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] == 0))); then
    skip "BASHOPTS requires Bash 4.1 or newer"
  fi
  printf '@test "dotglob stays enabled" { shopt -q dotglob; }\n' >"$BATS_TEST_TMPDIR/options.bats"

  reentrant_run env BASHOPTS=dotglob bats "$BATS_TEST_TMPDIR"
  [[ "$status" -eq 0 ]]
  [[ "${lines[1]}" = 'ok 1 dotglob stays enabled' ]]
}

@test "counting tests in a suite" {
  reentrant_run bats -c "$FIXTURE_ROOT/single"
  [ $status -eq 0 ]
  [ "$output" -eq 1 ]

  reentrant_run bats -c "$FIXTURE_ROOT/multiple"
  [ $status -eq 0 ]
  [ "$output" -eq 3 ]
}

@test "aggregated output of multiple tests in a suite" {
  reentrant_run bats "$FIXTURE_ROOT/multiple"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..3" ]
  echo "$output" | grep "^ok . truth"
  echo "$output" | grep "^ok . more truth"
  echo "$output" | grep "^ok . quasi-truth"
}

@test "aggregated output of multiple tests in a suite loading common constants" {
  reentrant_run bats "$FIXTURE_ROOT/multiple_load_constants"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..2" ]
  [ "${lines[1]}" = "ok 1 constant" ]
  [ "${lines[2]}" = "ok 2 constant (again)" ]
}

@test "a failing test in a suite results in an error exit code" {
  FLUNK=1 reentrant_run bats "$FIXTURE_ROOT/multiple"
  [ $status -eq 1 ]
  [ "${lines[0]}" = "1..3" ]
  echo "$output" | grep "^not ok . quasi-truth"
}

@test "errors when loading common helper from multiple tests in a suite" {
  reentrant_run bats "$FIXTURE_ROOT/errors_in_multiple_load"
  [ $status -eq 1 ]
  [ "${lines[0]}" = "1..1" ]
  [ "${lines[1]}" = "not ok 1 bats-gather-tests" ]

  [ "${lines[2]}" = "# (in file $RELATIVE_FIXTURE_ROOT/errors_in_multiple_load/test_helper.bash, line 1," ]
  [ "${lines[3]}" = "#  from function \`bats_internal_load' in file ${RELATIVE_BATS_ROOT}${BATS_LIBDIR}/bats-core/test_functions.bash, line 67," ]
  [ "${lines[4]}" = "#  from function \`bats_load_safe' in file ${RELATIVE_BATS_ROOT}${BATS_LIBDIR}/bats-core/test_functions.bash, line 98," ]
  [ "${lines[5]}" = "#  from function \`load' in file ${RELATIVE_BATS_ROOT}${BATS_LIBDIR}/bats-core/test_functions.bash, line 150," ]
  [ "${lines[6]}" = "#  in test file $RELATIVE_FIXTURE_ROOT/errors_in_multiple_load/a.bats, line 1)" ]
  # Bash 3 exits through errexit instead of returning the source command's status.
  if ((BASH_VERSINFO[0] >= 4)); then
    [ "${lines[7]}" = "#   \`load test_helper' failed" ]
    [ "${lines[8]}" = "# $FIXTURE_ROOT/errors_in_multiple_load/test_helper.bash: line 1: call-to-undefined-command: command not found" ]
    [ "${lines[9]}" = "# Error while sourcing library loader at '$FIXTURE_ROOT/errors_in_multiple_load/test_helper.bash'" ]
    [ "${#lines[@]}" -eq 10 ]
  else
    [ "${lines[7]}" = "#   \`load test_helper' failed with status 127" ]
    [ "${lines[8]}" = "# $FIXTURE_ROOT/errors_in_multiple_load/test_helper.bash: line 1: call-to-undefined-command: command not found" ]
    [ "${#lines[@]}" -eq 9 ]
  fi

}

@test "running an ad-hoc suite by specifying multiple test files" {
  reentrant_run bats "$FIXTURE_ROOT/multiple/a.bats" "$FIXTURE_ROOT/multiple/b.bats"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..3" ]
  echo "$output" | grep "^ok . truth"
  echo "$output" | grep "^ok . more truth"
  echo "$output" | grep "^ok . quasi-truth"
}

@test "extended syntax in suite" {
  emulate_bats_env
  FLUNK=1 reentrant_run bats-exec-suite -x "$FIXTURE_ROOT/multiple/"*.bats
  echo "output: $output"
  [ $status -eq 1 ]
  [ "${lines[0]}" = "1..3" ]
  [ "${lines[1]}" = "suite $FIXTURE_ROOT/multiple/a.bats" ]
  [ "${lines[2]}" = "begin 1 truth" ]
  [ "${lines[3]}" = "ok 1 truth" ]
  [ "${lines[4]}" = "suite $FIXTURE_ROOT/multiple/b.bats" ]
  [ "${lines[5]}" = "begin 2 more truth" ]
  [ "${lines[6]}" = "ok 2 more truth" ]
  [ "${lines[7]}" = "begin 3 quasi-truth" ]
  [ "${lines[8]}" = "not ok 3 quasi-truth" ]
}

@test "timing syntax in suite" {
  emulate_bats_env
  FLUNK=1 reentrant_run bats-exec-suite -T "$FIXTURE_ROOT/multiple/"*.bats
  echo "$output"
  [ $status -eq 1 ]
  [ "${lines[0]}" = "1..3" ]
  regex="ok 1 truth in [0-9]+ms"
  [[ "${lines[1]}" =~ $regex ]]
  regex="ok 2 more truth in [0-9]+ms"
  [[ "${lines[2]}" =~ $regex ]]
  regex="not ok 3 quasi-truth in [0-9]+ms"
  [[ "${lines[3]}" =~ $regex ]]
}

@test "extended timing syntax in suite" {
  emulate_bats_env
  FLUNK=1 reentrant_run bats-exec-suite -x -T "$FIXTURE_ROOT/multiple/"*.bats
  echo "$output"
  [ $status -eq 1 ]
  [ "${lines[0]}" = "1..3" ]
  [ "${lines[1]}" = "suite $FIXTURE_ROOT/multiple/a.bats" ]
  [ "${lines[2]}" = "begin 1 truth" ]
  regex="ok 1 truth in [0-9]+ms"
  [[ "${lines[3]}" =~ $regex ]]
  [ "${lines[4]}" = "suite $FIXTURE_ROOT/multiple/b.bats" ]
  [ "${lines[5]}" = "begin 2 more truth" ]
  regex="ok 2 more truth in [0-9]+ms"
  [[ "${lines[6]}" =~ $regex ]]
  [ "${lines[7]}" = "begin 3 quasi-truth" ]
  regex="not ok 3 quasi-truth in [0-9]+ms"
  [[ "${lines[8]}" =~ $regex ]]
}

@test "recursive support (short option)" {
  reentrant_run bats -r "${FIXTURE_ROOT}/recursive"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..2" ]
  [ "${lines[1]}" = "ok 1 another passing test" ]
  [ "${lines[2]}" = "ok 2 a passing test" ]
}

@test "recursive support (long option)" {
  reentrant_run bats --recursive "${FIXTURE_ROOT}/recursive"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..2" ]
  [ "${lines[1]}" = "ok 1 another passing test" ]
  [ "${lines[2]}" = "ok 2 a passing test" ]
}

@test "recursive support with symlinks" {
  if [[ ! -L "${FIXTURE_ROOT}/recursive_with_symlinks/test.bats" ]]; then
    skip "symbolic links aren't functional on OSTYPE=$OSTYPE"
  fi

  reentrant_run bats -r "${FIXTURE_ROOT}/recursive_with_symlinks"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..2" ]
  [ "${lines[1]}" = "ok 1 another passing test" ]
  [ "${lines[2]}" = "ok 2 a passing test" ]
}

@test "run entire suite when --filter isn't set" {
  reentrant_run bats "${FIXTURE_ROOT}/filter"
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
  reentrant_run bats -f 'ba[rz]' "${FIXTURE_ROOT}/filter"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '1..4' ]
  [ "${lines[1]}" = 'ok 1 --bar in a' ]
  [ "${lines[2]}" = 'ok 2 baz in a' ]
  [ "${lines[3]}" = 'ok 3 bar_in_b' ]
  [ "${lines[4]}" = 'ok 4 --baz_in_b' ]

  local prev_output="$output"

  reentrant_run bats --filter 'ba[rz]' "${FIXTURE_ROOT}/filter"
  [ "$status" -eq 0 ]
  [ "$output" = "$prev_output" ]
}

@test "--filter can handle regular expressions that contain [_- ]" {
  reentrant_run bats -f '--ba[rz][ _]in' "${FIXTURE_ROOT}/filter"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '1..2' ]
  [ "${lines[1]}" = 'ok 1 --bar in a' ]
  [ "${lines[2]}" = 'ok 2 --baz_in_b' ]
}

@test "--filter can handle regular expressions that start with ^" {
  reentrant_run bats -f '^ba[rz]' "${FIXTURE_ROOT}/filter"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '1..2' ]
  [ "${lines[1]}" = 'ok 1 baz in a' ]
  [ "${lines[2]}" = 'ok 2 bar_in_b' ]
}

@test "use --negative-filter to exclude specific test cases" {
  reentrant_run bats --negative-filter 'ba[rz]' "${FIXTURE_ROOT}/filter"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '1..5' ]
  [ "${lines[1]}" = 'ok 1 foo in a' ]
  [ "${lines[2]}" = 'ok 2 quux_in_b' ]
  [ "${lines[3]}" = 'ok 3 quux_in c' ]
  [ "${lines[4]}" = 'ok 4 xyzzy in c' ]
  [ "${lines[5]}" = 'ok 5 plugh_in c' ]
}

@test "--negative-filter together with --filter" {
  reentrant_run bats -f 'in a' --negative-filter 'baz' "${FIXTURE_ROOT}/filter"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = '1..2' ]
  [ "${lines[1]}" = 'ok 1 foo in a' ]
  [ "${lines[2]}" = 'ok 2 --bar in a' ]
}

@test "skip is handled correctly in setup, test, and teardown" {
  bats "${FIXTURE_ROOT}/skip"
}

@test "BATS_TEST_NUMBER starts at 1 in each individual test file" {
  reentrant_run bats "${FIXTURE_ROOT}/test_number"
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "Override BATS_FILE_EXTENSION with suite" {
  # shellcheck disable=SC2030
  REENTRANT_RUN_PRESERVE+=(BATS_FILE_EXTENSION)
  BATS_FILE_EXTENSION="test" reentrant_run bats "${FIXTURE_ROOT}/override_BATS_FILE_EXTENSION"
  echo "$output"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[0]}" = "1..1" ]
  [ "${lines[1]}" = "ok 1 test.test" ]
}

@test "Override BATS_FILE_EXTENSION with suite recursive" {
  # shellcheck disable=SC2030,SC2031
  REENTRANT_RUN_PRESERVE+=(BATS_FILE_EXTENSION)
  BATS_FILE_EXTENSION="other_extension" reentrant_run bats -r "${FIXTURE_ROOT}/override_BATS_FILE_EXTENSION"
  echo "$output"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[0]}" = "1..1" ]
  [ "${lines[1]}" = "ok 1 test.other_extension" ]
}
