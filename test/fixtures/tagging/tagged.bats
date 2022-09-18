@test "No tags" {
  :
}

# bats file_tags=file:tag:1

@test "Only file tags" {
  :
}

# bats test_tags=test:tag:1
@test "File and test tags" {
  :
}

# bats test_tags=test:tag:2
@test "File and other test tags" {
  :
}

# bats file_tags=
# bats test_tags=test:tag:3
@test "Only test tags" {
  :
}
