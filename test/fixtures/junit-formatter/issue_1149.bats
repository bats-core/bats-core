#!/usr/bin/env bats

# shellcheck disable=SC2034
BATS_TEST_RETRIES=1

@test "test fail" {
  false
}

@test "test foobar" {
  false
}
