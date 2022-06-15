
@test bats_version_lt {
    bats_require_minimum_version 1.5.0
    run ! bats_version_lt 1.0.0   1.0
    [ "$output" = "ERROR: version '1.0' must be of format <major>.<minor>.<patch>!" ]

    run ! bats_version_lt 1.0   1.0.0
    [ "$output" = "ERROR: version '1.0' must be of format <major>.<minor>.<patch>!" ]

    
    run -0 bats_version_lt  1.0.0  2.0.0
    run -0 bats_version_lt  1.2.0  2.0.0
    run -0 bats_version_lt  1.2.3  2.0.0
    run -0 bats_version_lt  1.0.0  1.1.0
    run -0 bats_version_lt  1.0.2  1.1.0
    run -0 bats_version_lt  1.0.0  1.0.1

    run -1 bats_version_lt  2.0.0  1.0.0
    run -1 bats_version_lt  2.0.0  1.2.0
    run -1 bats_version_lt  2.0.0  1.2.3
    run -1 bats_version_lt  1.1.0  1.0.0
    run -1 bats_version_lt  1.1.0  1.0.2
    run -1 bats_version_lt  1.0.1  1.0.0

    run -2 bats_version_lt  1.0.0  1.0.0
}

@test bats_require_minimum_version {
    [ "$BATS_GUARANTEED_MINIMUM_VERSION" = 0.0.0 ] # check default

    bats_require_minimum_version 0.1.2 # (a version that should be safe not to fail)
    [ "${BATS_GUARANTEED_MINIMUM_VERSION}" = 0.1.2 ]

    # a higher version should upgrade
    bats_require_minimum_version 0.2.3
    [ "${BATS_GUARANTEED_MINIMUM_VERSION}" = 0.2.3 ]

    # a lower version shoudl not change
    bats_require_minimum_version 0.1.2
    [ "${BATS_GUARANTEED_MINIMUM_VERSION}" = 0.2.3 ]
}

@test bats_binary_search {
    bats_require_minimum_version 1.5.0

    run -2 bats_binary_search "search-value"
    [ "$output" = "ERROR: bats_binary_search requires exactly 2 arguments: <search value> <array name>" ]

    # unset array = empty array: a bit unfortunate but we can't tell the difference (on older Bash?)
    unset no_array
    run -1 bats_binary_search "search-value" "no_array"

    # shellcheck disable=SC2034
    empty_array=()
    run -1 bats_binary_search "search-value" "empty_array"

    # shellcheck disable=SC2034
    odd_length_array=(1 2 3)
    run -1 bats_binary_search a odd_length_array
    run -0 bats_binary_search 1 odd_length_array
    run -0 bats_binary_search 2 odd_length_array
    run -0 bats_binary_search 3 odd_length_array

    # shellcheck disable=SC2034
    even_length_array=(1 2 3 4)
    run -1 bats_binary_search a even_length_array
    run -0 bats_binary_search 1 even_length_array
    run -0 bats_binary_search 2 even_length_array
    run -0 bats_binary_search 3 even_length_array
    run -0 bats_binary_search 4 even_length_array

}