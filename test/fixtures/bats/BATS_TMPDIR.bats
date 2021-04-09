@test "BATS_TMPDIR is set" {
  [ "${BATS_TMPDIR}" == "${expected:-}" ]
}

@test "BATS_RUN_TMPDIR has BATS_TMPDIR as a prefix" {
  local regex="^${BATS_TMPDIR}/.+"
  [[ ${BATS_RUN_TMPDIR} =~ ${regex} ]]
}
