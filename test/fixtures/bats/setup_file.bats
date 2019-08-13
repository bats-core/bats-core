
setup_file() {
    SETUP_FILE="$TMP_DIR/setup_file_test"
    touch "$SETUP_FILE"
}

@test "Setup_file" {
    [[ -f "$SETUP_FILE" ]]
}