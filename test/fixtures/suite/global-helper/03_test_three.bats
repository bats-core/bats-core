@test "test three" {
  [ "$(< ${BATS_TEST_SUITE_TMPDIR}/ghtestfile)" == "GH Test: test three" ]
}
