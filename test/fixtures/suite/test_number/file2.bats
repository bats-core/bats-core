#!/usr/bin/env bats

@test "first test in file 2" {
    echo "BATS_TEST_NUMBER=$BATS_TEST_NUMBER"
    [[ "$BATS_TEST_NUMBER" == 1 ]]
    echo "BATS_GLOBAL_TEST_NUMBER=$BATS_GLOBAL_TEST_NUMBER"
    [[ "$BATS_GLOBAL_TEST_NUMBER" == 4 ]]
}

@test "second test in file 2" {
    [[ "$BATS_TEST_NUMBER" == 2 ]]
    [[ "$BATS_GLOBAL_TEST_NUMBER" == 5 ]]
}

@test "BATS_TEST_NAMES is per file" {
    echo "${#BATS_TEST_NAMES[@]}"
    [[ "${#BATS_TEST_NAMES[@]}" == 3 ]]
}