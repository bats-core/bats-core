setup_suite() {
  :
}

teardown_suite() {
  # shellcheck disable=SC2034
  status=${STATUS?}
  return "${TEARDOWN_RETURN_CODE?}"
}
