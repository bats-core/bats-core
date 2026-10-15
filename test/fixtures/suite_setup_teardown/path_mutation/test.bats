@test "passing" {
  [ "$PATH" = "${PATH_MUTATION_VALUE:-/usr/bin:/bin}" ]
}
