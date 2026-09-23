dummy() {
  [ "$1" -eq "$2" ]
}

@test "simple" {
  run dummy 1 1
  [ "$status" -eq 0 ]
}

# bats test_tags=bats:focus
bats_test_function --description "Simple 2" -- dummy 2 2
