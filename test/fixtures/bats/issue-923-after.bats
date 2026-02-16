@test "collision defined after test" {
    echo test
}

@test "intermediate test" {
    :
}

# todo: how to prevent immediately after test?
test_collision_defined_after_test() {
    echo fun
}