@test "test two" {
  [ "$(tail -1 /tmp/ghtestfile)" == "GH Test: test two" ]
}
