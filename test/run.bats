@test "run --keep-empty-lines preserves leading empty lines" {
    run --keep-empty-lines -- echo -n $'\na'
    printf "'%s'\n" "${lines[@]}"
    [ "${lines[0]}" == '' ]
    [ "${lines[1]}" == a ]
    [ ${#lines[@]} -eq 2 ]
}

@test "run --keep-empty-lines preserves inner empty lines" {
    run --keep-empty-lines -- echo -n $'a\n\nb'
    printf "'%s'\n" "${lines[@]}"
    [ "${lines[0]}" == a ]
    [ "${lines[1]}" == '' ]
    [ "${lines[2]}" == b ]
    [ ${#lines[@]} -eq 3 ]
}

@test "run --keep-empty-lines preserves trailing empty lines" {
    run --keep-empty-lines -- echo -n $'a\n'
    printf "'%s'\n" "${lines[@]}"
    [ "${lines[0]}" == a ]
    [ "${lines[1]}" == '' ]
    [ ${#lines[@]} -eq 2 ]
}

@test "run --keep-empty-lines preserves multiple trailing empty lines" {
    run --keep-empty-lines -- echo -n $'a\n\n'
    printf "'%s'\n" "${lines[@]}"
    [ "${lines[0]}" == a ]
    [ "${lines[1]}" == '' ]
    [ "${lines[2]}" == '' ]
    [ ${#lines[@]} -eq 3 ]
}

@test "run --keep-empty-lines preserves non-empty trailing line" {
    run --keep-empty-lines -- echo -n $'a\nb'
    printf "'%s'\n" "${lines[@]}"
    [ "${lines[0]}" == a ]
    [ "${lines[1]}" == b ]
    [ ${#lines[@]} -eq 2 ]
}

print-stderr-stdout() {
    printf stdout
    printf stderr >&2
}

@test "run --output stdout does not print stderr" {   
    run --output stdout -- print-stderr-stdout
    echo "output='$output' stderr='$stderr'"
    [ "$output" = "stdout" ]
    [ ${#lines[@]} -eq 1 ]

    [ "${stderr-notset}" = notset ]
    [ ${#stderr_lines[@]} -eq 0 ]
}

@test "run --output stderr does not print stdout" {
    run --output stderr -- print-stderr-stdout
    echo "output='$output' stderr='$stderr'"
    [ "${output-notset}" = notset ]
    [ ${#lines[@]} -eq 0 ]

    [ "$stderr" = stderr ]
    [ ${#stderr_lines[@]} -eq 1 ]
}

@test "run --output separate splits output" {
    run --output separate -- print-stderr-stdout
    echo "output='$output' stderr='$stderr'"
    [ "$output" = stdout ]
    [ ${#lines[@]} -eq 1 ]

    [ "$stderr" = stderr ]
    [ ${#stderr_lines[@]} -eq 1 ]
}