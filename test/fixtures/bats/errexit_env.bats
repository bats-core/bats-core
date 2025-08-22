@test "check BATS_RUN_ERREXIT is set" {
  [ "${BATS_RUN_ERREXIT:-}" = "1" ]
}
