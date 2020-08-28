@test "Successful test with escape characters: \"'<>&(0x1b)" {
  true
}

@test "Failed test with escape characters: \"'<>&(0x1b)" {
  echo "<>'&" && false
}

@test "Skipped test with escape characters: \"'<>&(0x1b)" {
  skip "\"'<>&"
}