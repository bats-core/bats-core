@test 'Trigger BW01' {
    # shellcheck disable=SC2283
    run =0 actually-intended-command with some args # see issue #578
    # no $status check because that should be done above (but isn't!)
}