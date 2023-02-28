@test "BATS_* variables don't contain double slashes" {
  for var_name in ${!BATS_@}; do
    local var_value="${!var_name-}"
    if [[ "$var_value" == *'//'* ]]; then

      echo "$var_name contains // ${#var_value}: ${var_value}" && false
    fi
  done
}
