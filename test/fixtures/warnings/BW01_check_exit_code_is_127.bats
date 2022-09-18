@test "Don't trigger BW01 with checked exit code 127" {
  bats_require_minimum_version 1.5.0
  run -127 =0 actually-intended-command with some args
}
