setup() {
    export PATH="$(dirname $BATS_TEST_FILENAME):/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin"
}

@test "dummy" {
    echo "$PATH"
    run -0 date
    echo "$output"
    [ "${output}" = 'dummy date' ]
}