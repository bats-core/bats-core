@test "test two" {
  [ "$(< ${BATS_TEST_SUITE_TMPDIR}/ghtestfile)" == "GH Test: test two" ]
}
