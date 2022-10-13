load test_helper
fixtures run
bats_require_minimum_version 1.5.0

@test "run --keep-empty-lines preserves leading empty lines" {
  run --keep-empty-lines -- echo -n $'\na'
  printf "'%s'\n" "${lines[@]}"
  [ "${lines[0]}" == '' ]
  [ "${lines[1]}" == a ]
  [ ${#lines[@]} -eq 2 ]
}

@test "run --keep-empty-lines preserves inner empty lines" {
  run --keep-empty-lines -- echo -n $'a\n\nb'
  printf "'%s'\n" "${lines[@]}"
  [ "${lines[0]}" == a ]
  [ "${lines[1]}" == '' ]
  [ "${lines[2]}" == b ]
  [ ${#lines[@]} -eq 3 ]
}

@test "run --keep-empty-lines does not count trailing newline as extra line (see #708)" {
  run --keep-empty-lines -- echo -n $'a\n'
  printf "'%s'\n" "${lines[@]}"
  [ "${lines[0]}" == a ]
  [ ${#lines[@]} -eq 1 ]
}

@test "run --keep-empty-lines preserves trailing empty line" {
  run --keep-empty-lines -- echo -n $'a\n\n'
  printf "'%s'\n" "${lines[@]}"
  [ "${lines[0]}" == a ]
  [ "${lines[1]}" == '' ]
  [ ${#lines[@]} -eq 2 ]
}

@test "run --keep-empty-lines preserves non-empty trailing line" {
  run --keep-empty-lines -- echo -n $'a\nb'
  printf "'%s'\n" "${lines[@]}"
  [ "${lines[0]}" == a ]
  [ "${lines[1]}" == b ]
  [ ${#lines[@]} -eq 2 ]
}

@test "--keep-empty-lines has zero lines for empty output (see #573)" {
  run --keep-empty-lines true
  printf "'%s'\n" "${lines[@]}"
  [ ${#lines[@]} -eq 0 ]
}

print-stderr-stdout() {
  printf stdout
  printf stderr >&2
}

@test "run --separate-stderr splits output" {
  local stderr stderr_lines # silence shellcheck
  run --separate-stderr -- print-stderr-stdout
  echo "output='$output' stderr='$stderr'"
  [ "$output" = stdout ]
  [ ${#lines[@]} -eq 1 ]

  [ "$stderr" = stderr ]
  [ ${#stderr_lines[@]} -eq 1 ]
}

@test "run does not change set flags" {
  old_flags="$-"
  run true
  echo -- "$-" == "$old_flags"
  [ "$-" == "$old_flags" ]
}

# Positive assertions: each of these should succeed
@test "basic return-code checking" {
  run true
  run -0 true
  run '!' false
  run -1 false
  run -3 exit 3
  run -5 exit 5
  run -111 exit 111
  run -255 exit 255
  run -127 /no/such/command
}

@test "run exit code check output " {
  reentrant_run ! bats --tap "${FIXTURE_ROOT}/failing.bats"
  echo "$output"
  [ "${lines[0]}" == 1..5 ]
  [ "${lines[1]}" == "not ok 1 run -0 false" ]
  [ "${lines[2]}" == "# (in test file ${RELATIVE_FIXTURE_ROOT}/failing.bats, line 3)" ]
  [ "${lines[3]}" == "#   \`run -0 false' failed, expected exit code 0, got 1" ]
  [ "${lines[4]}" == "not ok 2 run -1 echo hi" ]
  [ "${lines[5]}" == "# (in test file ${RELATIVE_FIXTURE_ROOT}/failing.bats, line 7)" ]
  [ "${lines[6]}" == "#   \`run -1 echo hi' failed, expected exit code 1, got 0" ]
  [ "${lines[7]}" == "# hi" ]
  [ "${lines[8]}" == "not ok 3 run -2 exit 3" ]
  [ "${lines[9]}" == "# (in test file ${RELATIVE_FIXTURE_ROOT}/failing.bats, line 11)" ]
  [ "${lines[10]}" == "#   \`run -2 exit 3' failed, expected exit code 2, got 3" ]
  [ "${lines[11]}" == "not ok 4 run ! true" ]
  [ "${lines[12]}" == "# (in test file ${RELATIVE_FIXTURE_ROOT}/failing.bats, line 15)" ]
  [ "${lines[13]}" == "#   \`run ! true' failed, expected nonzero exit code!" ]
  [ "${lines[14]}" == "not ok 5 run multiple pass/fails" ]
  [ "${lines[15]}" == "# (in test file ${RELATIVE_FIXTURE_ROOT}/failing.bats, line 22)" ]
  [ "${lines[16]}" == "#   \`run -1 /etc' failed, expected exit code 1, got 126" ]
}

@test "run invalid exit code check error message" {
  reentrant_run ! bats --tap "${FIXTURE_ROOT}/invalid.bats"
  echo "$output"
  [ "${lines[0]}" == 1..2 ]
  [ "${lines[1]}" == "not ok 1 run '-4evah' echo hi" ]
  [ "${lines[2]}" == "# (in test file ${RELATIVE_FIXTURE_ROOT}/invalid.bats, line 2)" ]
  [ "${lines[3]}" == "#   \`run '-4evah' echo hi' failed" ]
  [ "${lines[4]}" == "# Usage error: run: '-NNN' requires numeric NNN (got: 4evah)" ]
  [ "${lines[5]}" == "not ok 2 run -256 echo hi" ]
  [ "${lines[6]}" == "# (in test file ${RELATIVE_FIXTURE_ROOT}/invalid.bats, line 6)" ]
  [ "${lines[7]}" == "#   \`run -256 echo hi' failed" ]
  [ "${lines[8]}" == "# Usage error: run: '-NNN': NNN must be <= 255 (got: 256)" ]
}

@test "run is not affected by IFS" {
  IFS=_
  run true
  [ "$status" -eq 0 ]
  IFS=0
  run true
  [ "$status" -eq 0 ]
}

@test "run does not change IFS" {
  local IFS=_
  run true
  [ "$IFS" = _ ]
  unset IFS
  run true
  [ "${IFS-(unset)}" = '(unset)' ]
}
