@test "more truth" {
  true
}

@test "quasi-truth" {
  [ "${FLUNK-}" == '' ]
}
