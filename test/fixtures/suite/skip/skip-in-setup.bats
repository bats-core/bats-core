#!/usr/bin/env bats

setup() {
  skip "This is not working (https://github.com/kata-containers/runtime/issues/175)"
}

@test "skip in setup" {
  true
}

@test "skip in setup and test" {
  skip
}