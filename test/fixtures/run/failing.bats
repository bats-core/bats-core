bats_require_minimum_version 1.5.0
@test "run -0 false" {
  run -0 false
}

@test "run -1 echo hi" {
  run -1 echo hi
}

@test "run -2 exit 3" {
  run -2 exit 3
}

@test "run ! true" {
  run ! true
}

@test "run multiple pass/fails" {
  run ! false
  run -0 echo hi
  run -127 /no/such/cmd
  run -1 /etc
}
