@test "a failing test" {
  true
  # shellcheck disable=SC2050
  [[ 1 == 2 ]]
}
