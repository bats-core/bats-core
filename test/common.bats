
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