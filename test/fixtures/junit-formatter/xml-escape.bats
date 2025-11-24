@test "Successful test with escape characters: \"'<>&[0m[K (0x1b)" {
  true
}

@test "Failed test with escape characters: \"'<>&[0m[K (0x1b)" {
  echo "<>'&[0m[K"$'\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1fstop' && false
}

@test "Skipped test with escape characters: \"'<>&[0m[K (0x1b)" {
  skip "\"'<>&[0m[K"
}
