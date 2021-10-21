@test "no failure prints no output" {
    run echo success
}

@test "failure prints output" {
    run -1 echo "fail hard"
}

@test "empty output on failure" {
    false
}