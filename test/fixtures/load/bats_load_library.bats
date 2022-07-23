[ -n "${HELPER_NAME:-}" ] || HELPER_NAME="test_helper"
bats_load_library "$HELPER_NAME"

@test "calling a loaded helper" {
  help_me
}
