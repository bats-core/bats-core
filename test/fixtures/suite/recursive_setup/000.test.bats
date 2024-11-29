setup_file() {
  export ZZZ=1
}

@test "Read an environment variable set by the root setup_suite" {
  [ $XXX == 1 ]
}
