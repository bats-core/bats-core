setup_file() {
  export YYY=1
}

@test "Check a future environment variable is unset" {
  [ -z "$ZZZ" ]
  [ "$YYY" == 1 ]
}
