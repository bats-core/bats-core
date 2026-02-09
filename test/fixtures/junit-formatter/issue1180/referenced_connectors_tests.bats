#!/usr/bin/env bats
# shellcheck shell=bash

function setup_file() {
  skip
}

function teardown_file() {
  echo "normal teardown_file stdout"
  echo "# Hash teardown_file stdout"
  echo "normal teardown_file stderr" >&2
  echo "# Hash teardown_file stderr" >&2
  echo "normal teardown_file fd3" >&3
  echo "# Hash teardown_file fd3" >&3
}

@test "skipped-and-junit-agrees" {
  echo "unexpected stdout as this should be skipped"
  echo "unexpected stderr as this should be skipped" >&2
  echo "unexpected fd3 as this should be skipped" >&3
}

@test "skipped-but-junit-reports-failure" {
  echo "unexpected stdout as this should be skipped"
  echo "unexpected stderr as this should be skipped" >&2
  echo "unexpected fd3 as this should be skipped" >&3
}
