setup() {
  # shellcheck disable=SC1091
  source "nonexistent file"
}

teardown() {
  echo "should not capture the next line"
  false
}

@test "sourcing nonexistent file fails in setup" {
  :
}
