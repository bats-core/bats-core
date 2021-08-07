teardown() {
  set -u
  # shellcheck disable=SC2154
  echo "$unset_parameter"
}

@test "referencing unset parameter fails in teardown" {
  :
}
