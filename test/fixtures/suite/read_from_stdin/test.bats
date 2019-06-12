#!/usr/bin/env bats

function cmd_using_stdin {
    # Just reading from stdin
    while read -r -t 1 foo; do
        if [ "$foo" == "EXIT" ]; then
            return 1
        fi
    done
    echo "OK"
    return 0
}

@test "test 1" {
    run cmd_using_stdin
    [ "$status" -eq 0 ]
    [ "$output" = "OK" ]
}

@test "test 2 with	TAB in name" {
    run cmd_using_stdin
    [ "$status" -eq 0 ]
    [ "$output" = "OK" ]
}

@test "test 3" {
    run cmd_using_stdin
    [ "$status" -eq 0 ]
    [ "$output" = "OK" ]
}
