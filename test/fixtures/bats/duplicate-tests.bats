
@test "gizmo test" "this does fail, as expected" {
  false
}

# This does not fail as expected
@test "gizmo test" {
  false
}

# This overrides any previous test from the suite with the same description
@test "gizmo test" {
  true
}
