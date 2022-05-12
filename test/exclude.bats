#!/usr/bin/env bats

load test_helper
fixtures exclude

# we test against following fixture/directory and test setup:
# 
# exclude
# ├── a
# │   └── baz.bats
# ├── b
# │   └── b1
# │       ├── quux.bats
# │       └── qux.bats
# ├── c
# │   └── c1
# │       ├── c2
# │       │   └── grault.bats
# │        └── corge.bats
# ├── bar.bats
# └── foo.bats 

@test "running all tests in fixture without exclude options" {
  run bats -r "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..7" ]
  echo "$output" | grep "^ok . foo"
  echo "$output" | grep "^ok . baz"
  echo "$output" | grep "^ok . bar"
  echo "$output" | grep "^ok . qux"
  echo "$output" | grep "^ok . quux"
  echo "$output" | grep "^ok . corge"
  echo "$output" | grep "^ok . grault"
}

@test "excluding all tests in fixture by short option -e" {
  run bats -rc -e "exclude" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "0" ]
}

@test "excluding all tests in fixture by long option --exclude" {
   run bats -rc --exclude "exclude" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "0" ]
}

@test "excluding folder c2 in fixture" {
  run bats -r -e "c2" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..6" ]
  echo "$output" | grep "^ok . foo"
  echo "$output" | grep "^ok . baz"
  echo "$output" | grep "^ok . bar"
  echo "$output" | grep "^ok . qux"
  echo "$output" | grep "^ok . quux"
  echo "$output" | grep "^ok . corge"
}

@test "excluding folder c in fixture" {
  run bats -r -e "c" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..5" ]
  echo "$output" | grep "^ok . foo"
  echo "$output" | grep "^ok . baz"
  echo "$output" | grep "^ok . bar"
  echo "$output" | grep "^ok . qux"
  echo "$output" | grep "^ok . quux"
}

@test "excluding test quux.bats in fixture" {
  run bats -r -e "quux.bats" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..6" ]
  echo "$output" | grep "^ok . foo"
  echo "$output" | grep "^ok . baz"
  echo "$output" | grep "^ok . bar"
  echo "$output" | grep "^ok . qux"
  echo "$output" | grep "^ok . corge"
  echo "$output" | grep "^ok . grault"
}

@test "excluding tests bar.bats & corge.bats in fixture" {
  run bats -r -e "bar.bats corge.bats" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..5" ]
  echo "$output" | grep "^ok . foo"
  echo "$output" | grep "^ok . baz"
  echo "$output" | grep "^ok . qux"
  echo "$output" | grep "^ok . quux"
  echo "$output" | grep "^ok . grault"
}

@test "excluding folder a & test qux.bats in fixture" {
  run bats -r -e "a qux.bats" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..5" ]
  echo "$output" | grep "^ok . foo"
  echo "$output" | grep "^ok . bar"
  echo "$output" | grep "^ok . quux"
  echo "$output" | grep "^ok . corge"
  echo "$output" | grep "^ok . grault"
}

@test "excluding tests foo.bats & qux.bats and folder c in fixture" {
  run bats -r -e "foo.bats qux.bats c" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..3" ]
  echo "$output" | grep "^ok . baz"
  echo "$output" | grep "^ok . bar"
  echo "$output" | grep "^ok . quux"
}

@test "excluding folder a & b and test grault.bats in fixture" {
  run bats -r -e "a b grault.bats" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..3" ]
  echo "$output" | grep "^ok . foo"
  echo "$output" | grep "^ok . bar"
  echo "$output" | grep "^ok . corge"
}

@test "excluding folder a, test bar.bats & quux.bats and folder c in fixture" {
  run bats -r -e "a bar.bats quux.bats c" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..2" ]
  echo "$output" | grep "^ok . foo"
  echo "$output" | grep "^ok . qux"
}

@test "excluding tests with pattern '.bats' in fixture" {
  run bats -rc -e ".bats" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "0" ]
}

@test "excluding tests with pattern '*.bats' in fixture" {
  run bats -rc -e "*.bats" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "0" ]
}

@test "excluding tests with pattern 'c*' in fixture" {
  run bats -r --exclude "c*" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..5" ]
  echo "$output" | grep "^ok . foo"
  echo "$output" | grep "^ok . baz"
  echo "$output" | grep "^ok . bar"
  echo "$output" | grep "^ok . qux"
  echo "$output" | grep "^ok . quux"
}

@test "excluding tests with pattern 'b1*' and test bar.bats in fixture" {
  run bats -r --exclude "b1* bar.bats" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..4" ]
  echo "$output" | grep "^ok . foo"
  echo "$output" | grep "^ok . baz"
  echo "$output" | grep "^ok . corge"
  echo "$output" | grep "^ok . grault"
}