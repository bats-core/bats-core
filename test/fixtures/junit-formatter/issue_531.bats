#!/usr/bin/env bats

setup_file() {
  echo "# setup_file stdout"
  echo "# setup_file fd3" >&3
}

teardown_file() {
  echo "# teardown_file stdout"
  echo "# teardown_file fd3" >&3
}

@test "My test" {
  echo "# test stdout"
  echo "# test fd3" >&3
}
