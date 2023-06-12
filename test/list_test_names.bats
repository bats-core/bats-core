#!/usr/bin/env bats

bats_require_minimum_version 1.9.0

setup() {
  load test_helper
  fixtures list_test_names
}

@test "list test names can decode test names" {
  run -0 bin/bats -l "$FIXTURE_ROOT"/decode.bats
}

@test "list test can print cryptic test names" {
  run -0 bin/bats -l "$FIXTURE_ROOT"/cryptic.bats
  [[ "${#lines[@]}" -eq 5 ]]
  [[ "${lines[0]}" == "nothing_special at-this-one" ]]
  [[ "${lines[1]}" == "don't fail on 'single' or \"Double\" quotes" ]]
  [[ "${lines[2]}" == "handles braces < [ } ({[]}) )(" ]]
  # shellcheck disable=SC2016
  [[ "${lines[3]}" == 'handles `backticks`' ]]
  [[ "${lines[4]}" == 'handles \backslash incl sequences \n \r \t' ]]
}

@test "list all tests (-l | --list)" {
  run -0 bin/bats -l "$FIXTURE_ROOT"/file*
  [[ "${#lines[@]}" -eq 10 ]]
  [[ "${lines[0]}" == "First One" ]]
  [[ "${lines[1]}" == "First Two" ]]
  [[ "${lines[2]}" == "First Three failed" ]]
  [[ "${lines[3]}" == "First Four test_tag" ]]
  [[ "${lines[4]}" == "First Five test_tag failed" ]]
  [[ "${lines[5]}" == "Second One" ]]
  [[ "${lines[6]}" == "Second Two" ]]
  [[ "${lines[7]}" == "Second Three failed" ]]
  [[ "${lines[8]}" == "Second Four test_tag" ]]
  [[ "${lines[9]}" == "Second Five test_tag failed" ]]
}

@test "list all tests (-L | --list-with-filename)" {
  run -0 bin/bats -L "$FIXTURE_ROOT"/file*
  [[ "${#lines[@]}" -eq 10 ]]
  [[ "${lines[0]}" == "$FIXTURE_ROOT/file_first.bats : First One" ]]
  [[ "${lines[1]}" == "$FIXTURE_ROOT/file_first.bats : First Two" ]]
  [[ "${lines[2]}" == "$FIXTURE_ROOT/file_first.bats : First Three failed" ]]
  [[ "${lines[3]}" == "$FIXTURE_ROOT/file_first.bats : First Four test_tag" ]]
  [[ "${lines[4]}" == "$FIXTURE_ROOT/file_first.bats : First Five test_tag failed" ]]
  [[ "${lines[5]}" == "$FIXTURE_ROOT/file_second.bats : Second One" ]]
  [[ "${lines[6]}" == "$FIXTURE_ROOT/file_second.bats : Second Two" ]]
  [[ "${lines[7]}" == "$FIXTURE_ROOT/file_second.bats : Second Three failed" ]]
  [[ "${lines[8]}" == "$FIXTURE_ROOT/file_second.bats : Second Four test_tag" ]]
  [[ "${lines[9]}" == "$FIXTURE_ROOT/file_second.bats : Second Five test_tag failed" ]]
}

@test "list filtered 'First' tests" {
  run -0 bin/bats -l --filter 'First' "$FIXTURE_ROOT"/file*
  [[ "${#lines[@]}" -eq 5 ]]
  [[ "${lines[0]}" == "First One" ]]
  [[ "${lines[1]}" == "First Two" ]]
  [[ "${lines[2]}" == "First Three failed" ]]
  [[ "${lines[3]}" == "First Four test_tag" ]]
  [[ "${lines[4]}" == "First Five test_tag failed" ]]
}

@test "list filtered 'One' tests" {
  run -0 bin/bats -l --filter 'One' "$FIXTURE_ROOT"/file*
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "${lines[0]}" == "First One" ]]
  [[ "${lines[1]}" == "Second One" ]]
}

@test "list file_tagged tests" {
  run -0 bin/bats -l --filter-tags second:file "$FIXTURE_ROOT"/file*
  [[ "${#lines[@]}" -eq 5 ]]
  [[ "${lines[0]}" == "Second One" ]]
  [[ "${lines[1]}" == "Second Two" ]]
  [[ "${lines[2]}" == "Second Three failed" ]]
  [[ "${lines[3]}" == "Second Four test_tag" ]]
  [[ "${lines[4]}" == "Second Five test_tag failed" ]]
}

@test "list --filter failed tests" {
  run -1 bin/bats "$FIXTURE_ROOT/file_first.bats"
  [[ "${#lines[@]}" -eq 11 ]]
  [[ "${lines[0]}" == "1..5" ]]
  [[ "${lines[1]}" == "ok 1 First One" ]]
  [[ "${lines[2]}" == "ok 2 First Two" ]]
  [[ "${lines[3]}" == "not ok 3 First Three failed" ]]
  [[ "${lines[4]}" == "# (in test file test/fixtures/list_test_names/file_first.bats, line 5)" ]]
  [[ "${lines[5]}" == "#   \`@test \"First Three failed\" { false; }' failed" ]]
  [[ "${lines[6]}" == "ok 4 First Four test_tag" ]]
  [[ "${lines[7]}" == "not ok 5 First Five test_tag failed" ]]
  [[ "${lines[8]}" == "# tags: first:test tag:failed" ]]
  [[ "${lines[9]}" == "# (in test file test/fixtures/list_test_names/file_first.bats, line 9)" ]]
  [[ "${lines[10]}" == "#   \`@test \"First Five test_tag failed\" { false; }' failed" ]]
  # now rerun with -l to list failed tests
  run -0 bin/bats -l --filter failed "$FIXTURE_ROOT/file_first.bats"
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "${lines[0]}" == "First Three failed" ]]
  [[ "${lines[1]}" == "First Five test_tag failed" ]]
}
@test "list '--filter failed --filter-tags' tests" {
  run -1 bin/bats "$FIXTURE_ROOT/file_first.bats"
  [[ "${#lines[@]}" -eq 11 ]]
  [[ "${lines[0]}" == "1..5" ]]
  [[ "${lines[1]}" == "ok 1 First One" ]]
  [[ "${lines[2]}" == "ok 2 First Two" ]]
  [[ "${lines[3]}" == "not ok 3 First Three failed" ]]
  [[ "${lines[4]}" == "# (in test file test/fixtures/list_test_names/file_first.bats, line 5)" ]]
  [[ "${lines[5]}" == "#   \`@test \"First Three failed\" { false; }' failed" ]]
  [[ "${lines[6]}" == "ok 4 First Four test_tag" ]]
  [[ "${lines[7]}" == "not ok 5 First Five test_tag failed" ]]
  [[ "${lines[8]}" == "# tags: first:test tag:failed" ]]
  [[ "${lines[9]}" == "# (in test file test/fixtures/list_test_names/file_first.bats, line 9)" ]]
  [[ "${lines[10]}" == "#   \`@test \"First Five test_tag failed\" { false; }' failed" ]]
  # now rerun with -l to list failed, tagged tests
  run -0 bin/bats -l --filter failed --filter-tags tag:failed "$FIXTURE_ROOT/file_first.bats"
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "${lines[0]}" == "First Five test_tag failed" ]]
}

# should have status 0 but validator.bash fails on empty output
@test "don't' print anything if no tests are found" {
  run -1 bin/bats -l "$FIXTURE_ROOT"/empty.bats
  [[ "${#lines[@]}" -eq 0 ]]
  [[ "$output" -eq "" ]]
}

# should have status 1 but validator.bash fails on empty output
@test "don't' print anything if all tests are filtered out" {
  run -1 bin/bats -l --filter 'Oops' "$FIXTURE_ROOT"/file*
  [[ "${#lines[@]}" -eq 0 ]]
  [[ "$output" -eq "" ]]
}

@test "print test count and names if -c and -l are given" {
  run -0 bin/bats -lc --filter 'One' "$FIXTURE_ROOT"/file*
  [[ "${#lines[@]}" -eq 3 ]]
  [[ "${lines[0]}" == "2" ]]
  [[ "${lines[1]}" == "First One" ]]
  [[ "${lines[2]}" == "Second One" ]]
}
