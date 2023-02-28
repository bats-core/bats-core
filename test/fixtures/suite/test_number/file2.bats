#!/usr/bin/env bats

@test "first test in file 2" {
  echo "BATS_TEST_NUMBER=$BATS_TEST_NUMBER"
  [ "$BATS_TEST_NUMBER" -eq 1 ]
  echo "BATS_SUITE_TEST_NUMBER=$BATS_SUITE_TEST_NUMBER"
  [ "$BATS_SUITE_TEST_NUMBER" -eq 4 ]
}

@test "second test in file 2" {
  [ "$BATS_TEST_NUMBER" -eq 2 ]
  [ "$BATS_SUITE_TEST_NUMBER" -eq 5 ]
}

@test "second test in file 3" {
  [ "$BATS_TEST_NUMBER" -eq 3 ]
  [ "$BATS_SUITE_TEST_NUMBER" -eq 6 ]
}

@test "BATS_TEST_NAMES is per file" {
  echo "${#BATS_TEST_NAMES[@]} ${BATS_TEST_NAMES[0]}"
  [ "${#BATS_TEST_NAMES[@]}" -eq 4 ]
  [ "${BATS_TEST_NAMES[0]}" == test_first_test_in_file_2 ]
}
