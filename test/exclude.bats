#!/usr/bin/env bats

load test_helper
fixtures exclude

# we test against following fixture/directory setup:
# 
# exclude
# ├── a0
# │   └── baz.bats
# ├── b0
# │   └── b1
# │       ├── quux.bats
# │       └── qux.bats
# ├── c0
# │   └── c1
# │       ├── c2
# │       │   └── grault.bats
# │        └── corge.bats
# ├── bar.bats
# └── foo.bats 
#
# note: 
#   directory names has to be chosen wisely for interoperability with WSL:
#   avoid directory names with one letter because it could interfere with 
#   mounted windows drives => /mnt/X/.../exclude/X
#   e.g. `bats -e "c" fixtures/exclude` operates on "/mnt/c/.../exclude/c/..."
#   all tests would be excluded in such cases, no matter what! 

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

@test "excluding folder c0 in fixture" {
  run bats -r -e "c0" "$FIXTURE_ROOT"
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

@test "excluding folder a0 & test qux.bats in fixture" {
  run bats -r -e "a0 qux.bats" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..5" ]
  echo "$output" | grep "^ok . foo"
  echo "$output" | grep "^ok . bar"
  echo "$output" | grep "^ok . quux"
  echo "$output" | grep "^ok . corge"
  echo "$output" | grep "^ok . grault"
}

@test "excluding tests foo.bats & qux.bats and folder c0 in fixture" {
  run bats -r -e "foo.bats qux.bats c0" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..3" ]
  echo "$output" | grep "^ok . baz"
  echo "$output" | grep "^ok . bar"
  echo "$output" | grep "^ok . quux"
}

@test "excluding folder a0 & b0 and test grault.bats in fixture" {
  run bats -r -e "a0 b0 grault.bats" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..3" ]
  echo "$output" | grep "^ok . foo"
  echo "$output" | grep "^ok . bar"
  echo "$output" | grep "^ok . corge"
}

@test "excluding folder a0, test bar.bats & quux.bats and folder c0 in fixture" {
  run bats -r -e "a0 bar.bats quux.bats c0" "$FIXTURE_ROOT"
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

@test "excluding tests with pattern 'b0*' in fixture" {
  run bats -r --exclude "b0*" "$FIXTURE_ROOT"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "1..5" ]
  echo "$output" | grep "^ok . foo"
  echo "$output" | grep "^ok . baz"
  echo "$output" | grep "^ok . bar"
  echo "$output" | grep "^ok . corge"
  echo "$output" | grep "^ok . grault"
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