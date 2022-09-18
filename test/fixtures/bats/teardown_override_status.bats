teardown() {
  status=${STATUS?}
  return "${TEARDOWN_RETURN_CODE?}"
}

@test "return expected code" {
  return "${TEST_RETURN_CODE?}"
}
