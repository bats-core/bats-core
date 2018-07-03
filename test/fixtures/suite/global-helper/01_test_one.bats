@test "test one" {
  [ "$(tail -1 /tmp/ghtestfile)" == "GH Test: test one" ]
}
