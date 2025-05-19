@test "kcov is invoked correctly" {
  bats_require_minimum_version 1.5.0
  local output_file="${BATS_TEST_TMPDIR}/kcov-was-run"
  cat > "${BATS_TEST_TMPDIR}/kcov" <<FAKE_KCOV
!#/bin/bash

echo "\$@" > "${BATS_TEST_TMPDIR}/kcov-was-run"
FAKE_KCOV
  chmod 755 "${BATS_TEST_TMPDIR}/kcov"

  # Use our fake kcov.
  PATH="${BATS_TEST_TMPDIR}:${PATH}"
  run -0 true

  [[ -e "${output_file}" ]]
  local output_contents
  output_contents="$(< "${output_file}")"
  local expected="--bash-dont-parse-binary-dir /TMPDIR/FOO true"
  if [[ "${output_contents}" != "${expected}" ]]; then
    echo "Bad output: expecting \"${expected}\", got \"${output_contents}\"" >&2
    false
  fi
}
