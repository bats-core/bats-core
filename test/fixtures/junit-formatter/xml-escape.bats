@test "Successful test with escape characters: \"'<>&[0m[K (0x1b)" {
  true
}

@test "Failed test with escape characters: \"'<>&[0m[K (0x1b)" {
  echo "<>'&[0m[K" && false
}

@test "Skipped test with escape characters: \"'<>&[0m[K (0x1b)" {
  skip "\"'<>&[0m[K"
}
