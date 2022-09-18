@test "error in test" {
  printf 'foo\nbar'
  false
}

@test "test function returns nonzero" {
  printf 'foo\nbar'
  return 1
}
