setup_suite() {
  echo setup_suite stdout
  echo setup_suite stderr >&2
}

teardown_suite() {
  echo teardown_suite stdout
  echo teardown_suite stderr >&2
  false
}
