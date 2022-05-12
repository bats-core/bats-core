@test "no failure prints no output" {
    run echo success
}
bats_require_minimum_version 1.5.0 # don't be fooled by order, this will run before the test above!
@test "failure prints output" {
    run -1 echo "fail hard"
}

@test "empty output on failure" {
    false
}