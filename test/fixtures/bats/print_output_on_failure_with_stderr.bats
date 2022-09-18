@test "no failure prints no output" {
  run echo success
}

@test "failure prints output" {
  bats_require_minimum_version 1.5.0
  run -1 --separate-stderr bash -c 'echo "fail hard"; echo with stderr >&2'
}

@test "empty output on failure" {
  false
}
