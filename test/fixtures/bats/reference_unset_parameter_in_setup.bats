setup() {
  set -u
  # shellcheck disable=SC2154
  echo "$unset_parameter"
}

teardown() {
  echo "should not capture the next line"
  false
}

@test "referencing unset parameter fails in setup" {
  :
}
