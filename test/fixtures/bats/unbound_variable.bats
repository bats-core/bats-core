set -u

@test "access unbound variable" {
    unset unset_variable
    # Add a line for checking line#
    foo=$unset_variable
}
