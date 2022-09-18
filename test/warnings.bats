#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  load test_helper
  fixtures warnings
  if [[ $BATS_ROOT == "$BATS_CWD" ]]; then
    RELATIVE_BATS_ROOT=''
  else
    RELATIVE_BATS_ROOT=${BATS_ROOT#"$BATS_CWD"/}
  fi
  if [[ -n "$RELATIVE_BATS_ROOT" && "$RELATIVE_BATS_ROOT" != */ ]]; then
    RELATIVE_BATS_ROOT+=/
  fi
  echo "RELATIVE_BATS_ROOT=$RELATIVE_BATS_ROOT" "BATS_ROOT=$BATS_ROOT" "BATS_CWD=$BATS_CWD"
}

@test "invalid warning is an error" {
  REENTRANT_RUN_PRESERVE+=(BATS_WARNING_SHORT_DESCS)
  reentrant_run -1 bats_generate_warning invalid-number
  [[ "$output" == "Invalid Bats warning number 'invalid-number'. It must be an integer between 1 and "* ]]
}

@test "BW01 is printed when \`run\`ing a (non-existant) command with exit code 127 without exit code check" {
  reentrant_run -0 bats "$FIXTURE_ROOT/BW01.bats"
  [ "${lines[0]}" == "1..1" ]
  [ "${lines[1]}" == "ok 1 Trigger BW01" ]
  [ "${lines[2]}" == "The following warnings were encountered during tests:" ]
  [ "${lines[3]}" == "BW01: \`run\`'s command \`=0 actually-intended-command with some args\` exited with code 127, indicating 'Command not found'. Use run's return code checks, e.g. \`run -127\`, to fix this message." ]
  [[ "${lines[4]}" == "      (from function \`run' in file ${RELATIVE_BATS_ROOT}lib/bats-core/test_functions.bash, line"* ]]
  [ "${lines[5]}" == "       in test file $RELATIVE_FIXTURE_ROOT/BW01.bats, line 3)" ]
}

@test "BW01 is not printed when \`run\`ing a (non-existant) command with exit code 127 with exit code check" {
  reentrant_run -0 bats "$FIXTURE_ROOT/BW01_check_exit_code_is_127.bats"
  [ "${lines[0]}" == "1..1" ]
  [ "${lines[1]}" == "ok 1 Don't trigger BW01 with checked exit code 127" ]
  [ "${#lines[@]}" -eq 2 ]
}

@test "BW01 is not printed when \`run\`ing a command with exit code !=127 without exit code check" {
  reentrant_run -0 bats "$FIXTURE_ROOT/BW01_no_exit_code_check_no_exit_code_127.bats"
  [ "${lines[0]}" == "1..1" ]
  [ "${lines[1]}" == "ok 1 Don't trigger BW01 with exit code !=127 and no check" ]
  [ "${#lines[@]}" -eq 2 ]
}

@test "BW02 is printed when run uses parameters without guaranteed version >= 1.5.0" {
  reentrant_run -0 bats "$FIXTURE_ROOT/BW02.bats"
  [ "${lines[0]}" == "1..1" ]
  [ "${lines[1]}" == "ok 1 Trigger BW02" ]
  [ "${lines[2]}" == "The following warnings were encountered during tests:" ]
  [ "${lines[3]}" == "BW02: Using flags on \`run\` requires at least BATS_VERSION=1.5.0. Use \`bats_require_minimum_version 1.5.0\` to fix this message." ]
  [[ "${lines[4]}" == "      (from function \`bats_warn_minimum_guaranteed_version' in file ${RELATIVE_BATS_ROOT}lib/bats-core/warnings.bash, line "* ]]
  [[ "${lines[5]}" == "       from function \`run' in file ${RELATIVE_BATS_ROOT}lib/bats-core/test_functions.bash, line"* ]]
  [ "${lines[6]}" == "       in test file $RELATIVE_FIXTURE_ROOT/BW02.bats, line 2)" ]
}

@test "BW03 is printed when a test file defines setup_suite and setup_suite is not defined" {
  reentrant_run -0 bats "$FIXTURE_ROOT/BW03/define_setup_suite_in_wrong_file.bats"
  [ "${lines[0]}" == "1..1" ]
  [ "${lines[1]}" == "ok 1 test" ]
  [ "${lines[2]}" == "The following warnings were encountered during tests:" ]
  [ "${lines[3]}" == "BW03: \`setup_suite\` is visible to test file '${FIXTURE_ROOT}/BW03/define_setup_suite_in_wrong_file.bats', but was not executed. It belongs into 'setup_suite.bash' to be picked up automatically." ]
  [ "${#lines[@]}" -eq 4 ]
}

@test "BW03 is not printed when a test file defines setup_suite but setup_suite was completed" {
  reentrant_run -0 bats "$FIXTURE_ROOT/BW03/define_setup_suite_in_wrong_file.bats" --setup-suite-file "$FIXTURE_ROOT/BW03/non_default_setup_suite.bash"
  [ "${lines[0]}" == "1..1" ]
  [ "${lines[1]}" == "ok 1 test" ]
  [ "${#lines[@]}" -eq 2 ]
}

@test "BW03 can be suppressed by setting BATS_SETUP_SUITE_COMPLETED" {
  reentrant_run -0 bats "$FIXTURE_ROOT/BW03/suppress_warning.bats"
  [ "${lines[0]}" == "1..1" ]
  [ "${lines[1]}" == "ok 1 test" ]
  [ "${#lines[@]}" -eq 2 ]
}
