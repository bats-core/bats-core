teardown() {
  # shellcheck disable=SC1091
  source "nonexistent file"
}

@test "sourcing nonexistent file fails in teardown" {
  :
}
