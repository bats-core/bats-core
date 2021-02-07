setup_file() {
    echo "setup_file $BATS_TEST_FILENAME" >> "$FILE_MARKER"
    sleep 3
}

teardown_file() {
    echo "teardown_file $BATS_TEST_FILENAME" >> "$FILE_MARKER"
}

@test "nothing" {
    true
}