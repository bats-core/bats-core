@test "launcher preserves BATS_LIB_PATH" {
  [ "$BATS_LIB_PATH" = 'C:\unconverted' ]
}
