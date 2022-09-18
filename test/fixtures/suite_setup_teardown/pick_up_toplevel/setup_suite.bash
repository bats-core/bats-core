setup_suite() {
  echo "${BASH_SOURCE[0]}" setup_suite >>"$LOGFILE"
}

teardown_suite() {
  echo "${BASH_SOURCE[0]}" teardown_suite >>"$LOGFILE"
}
