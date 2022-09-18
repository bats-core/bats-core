@test "no unprefixed variables" {
  declare -p >"${BATS_DECLARED_VARIABLES_FILE?}"
}
