#!/usr/bin/env bats

@test "passing" {
  local value=1
  [ "$value" -eq 1 ]
}
