@test "run --keep-empty-lines preserves leading empty lines" {
    run --keep-empty-lines echo -n $'\na'
    [ "${lines[0]}" == '' ]
    [ "${lines[1]}" == a ]
    [ ${#lines[@]} -eq 2 ]
}

@test "run --keep-empty-lines preserves inner empty lines" {
    run --keep-empty-lines echo -n $'a\n\nb'
    [ "${lines[0]}" == a ]
    [ "${lines[1]}" == '' ]
    [ "${lines[2]}" == b ]
    [ ${#lines[@]} -eq 3 ]
}

@test "run --keep-empty-lines preserves trailing empty lines" {
    run --keep-empty-lines echo -n $'a\n'
    [ "${lines[0]}" == a ]
    [ "${lines[1]}" == '' ]
    [ ${#lines[@]} -eq 2 ]
}

@test "run --keep-empty-lines preserves multiple trailing empty lines" {
    run --keep-empty-lines echo -n $'a\n\n'
    [ "${lines[0]}" == a ]
    [ "${lines[1]}" == '' ]
    [ "${lines[2]}" == '' ]
    [ ${#lines[@]} -eq 3 ]
}

@test "run --keep-empty-lines preserves non-empty trailing line" {
    run --keep-empty-lines echo -n $'a\nb'
    [ "${lines[0]}" == a ]
    [ "${lines[1]}" == b ]
    [ ${#lines[@]} -eq 2 ]
}