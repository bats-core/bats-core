@test "a complex failing test" {
  echo 123
  run bats "$BATS_TEST_DIRNAME/failing.bats"
  [ $status -eq 0 ]
}
