@test "Read both environment variables set by this and parent setup_suite's" {
  [ $WWW == 1 ]
  [ $ZZZ == 1 ]
}
