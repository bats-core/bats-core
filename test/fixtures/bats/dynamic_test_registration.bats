@test "normal test1" {
    true
}

dynamic_test_with_description() {
    :
}

bats_test_function --description "Some description" -- dynamic_test_with_description

dynamic_test_without_description() {
    :
}

bats_test_function -- dynamic_test_without_description

parametrized_test() {
    echo "$BATS_TEST_NAME: $1"
    false
}

for val in 1 2 "th ree"; do
    bats_test_function -- parametrized_test "$val"
done

@test "normal test2" {
    true
}