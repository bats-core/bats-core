@test "BATS_BUCKET is passed through different test files" {
  [ "$BATS_BUCKET" = 'value' ]
}
