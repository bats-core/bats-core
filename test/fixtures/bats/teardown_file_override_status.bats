teardown_file() {
  # shellcheck disable=SC2034
  status=${STATUS?}
  return "${TEARDOWN_RETURN_CODE?}"
}

@test "return expected code" {
  return "${TEST_RETURN_CODE?}"
}
