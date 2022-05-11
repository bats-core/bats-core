@test "Don't trigger BW01 with checked exit code 127" {
    run -127 =0 actually-intended-command with some args
}