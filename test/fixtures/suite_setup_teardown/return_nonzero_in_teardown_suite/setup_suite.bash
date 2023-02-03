setup_suite() {
  :
}

teardown_suite() {
  echo "teardown_suite before" >&2
  return 1
  # shellcheck disable=SC2317
  echo "teardown_suite after" >&2
}
