BATS_TEST_RETRIES=2 # means three tries per test

log_caller() {
  printf "%s %s %s\n" "${BATS_TEST_NAME:-}" "${FUNCNAME[1]}" "${BATS_TEST_TRY_NUMBER:-}" >>"${LOG?}"
}

setup_file() {
  log_caller
}

teardown_file() {
  log_caller
}

setup() {
  log_caller
}

teardown() {
  log_caller
}

@test "Fail all" {
  log_caller
  false
}

@test "Fail once" {
  log_caller
  ((BATS_TEST_TRY_NUMBER > 1)) || false
}

@test "Override retries" {
  log_caller
  # shellcheck disable=SC2034
  BATS_TEST_RETRIES=1
  ((BATS_TEST_TRY_NUMBER > 2)) || false
}
