#!/usr/bin/env bats

setup() {
  set -u
}

@test "example" {
  echo $unbound_variable
}
