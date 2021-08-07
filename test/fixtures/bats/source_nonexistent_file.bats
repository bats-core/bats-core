@test "sourcing nonexistent file fails" {
  # shellcheck disable=SC1091
  source "nonexistent file"
}
