LOG="$BATS_TEST_SUITE_TMPDIR/after_run.log"

after_run() {
  echo "after_run" >> "$LOG"
  #echo "$BATS_TEST_NAME RUN" >> "$LOG"
  #echo "# in after_run" >&3
}
teardown() {
  echo "$BATS_TEST_NAME" >> "$LOG"
}


@test "one" {
  true
}

@test "two" {
  false
}

@test "three" {
  true
}
