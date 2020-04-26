@test "a test marked todo that fails" {
  todo
  false
}

@test "a test marked todo with a reason that fails" {
  todo "a reason"
  false
}

@test "a test marked todo that passes" {
  todo
  true
}

@test "a test marked todo with a reason that passes" {
  todo "a reason"
  true
}
