@test "setting a variable" {
  # shellcheck disable=SC2030
  variable=1
  [ $variable -eq 1 ]
}

@test "variables do not persist across tests" {
  # shellcheck disable=SC2031
  [ -z "${variable:-}" ]
}
