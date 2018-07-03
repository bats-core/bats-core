@test "test one" {
  [ "$(< ${BATS_TEST_SUITE_TMPDIR}/ghtestfile)" == "GH Test: test one" ]
}
