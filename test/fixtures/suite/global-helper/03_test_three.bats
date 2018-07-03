@test "test three" {
  [ "$(tail -1 /tmp/ghtestfile)" == "GH Test: test three" ]
}
