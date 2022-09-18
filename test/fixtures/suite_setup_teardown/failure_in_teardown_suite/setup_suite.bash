setup_suite() {
  :
}

teardown_suite() {
  echo "teardown_suite before" >&2
  false
  echo "teardown_suite after" >&2
}
