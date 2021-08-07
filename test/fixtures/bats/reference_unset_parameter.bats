@test "referencing unset parameter fails" {
  set -u
  # shellcheck disable=SC2154
  echo "$unset_parameter"
}
