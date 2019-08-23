setup_file() {
    echo "$BATS_TEST_FILENAME" >> "$LOG"
}

@test "Setup_file" {
    [[ -f "$LOG" ]]
    run wc -l < "$LOG"
    echo $output
    [[ $output -eq 1 ]]
}

@test "Second setup_file test" {
    # still got only one setup!
    [[ -f "$LOG" ]]
    run wc -l < "$LOG"
    echo $output
    [[ $output -eq 1 ]]
}