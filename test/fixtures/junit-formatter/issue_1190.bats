#!/usr/bin/env bats

@test "skipped with output" {
  echo "output"
  skip
}
