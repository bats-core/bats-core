@test "missing helper after successful load" {
  load test_helper
  load nonexistent
}

@test "helper returning nonzero after successful load" {
  load test_helper
  load return1
}

@test "missing library after successful load" {
  bats_load_library "$BATS_TEST_DIRNAME/test_helper.bash"
  bats_load_library "$BATS_TEST_DIRNAME/nonexistent.bash"
}

@test "library returning nonzero after successful load" {
  bats_load_library "$BATS_TEST_DIRNAME/test_helper.bash"
  bats_load_library "$BATS_TEST_DIRNAME/return1.bash"
}
