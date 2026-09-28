setup_file() {
  # shellcheck disable=SC2034
  if (BATS_FILE_FIRST_TEST_NUMBER_IN_SUITE=42) 2>/dev/null; then
    return 1
  fi
}

@test "test" {
  true
}
