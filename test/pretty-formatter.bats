
@test "Timing printout shows milliseconds" {
    format_example_stream() {
        bats-format-pretty -T  <<HERE
1..1
suite /test/path
begin 1 test
ok 1 test in 123ms
HERE
    }
    run format_example_stream
    echo "$output"
    [[ "${lines[0]}" == *'[123]'* ]]
}