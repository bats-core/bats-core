setup_suite() {
  :
}

teardown_suite() {
  echo "teardown_suite before" >&2
  return 1
  echo "teardown_suite after" >&2
}
