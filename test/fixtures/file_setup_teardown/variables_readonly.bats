assert_variables_are_readonly() {
  local variable writable=
  for variable in ${VARIABLES_TO_REASSIGN?}; do
    if (eval "$variable=changed") 2>/dev/null; then
      echo "$variable is writable" >&2
      writable=1
    fi
  done
  [[ ! $writable ]]
}

setup_file() {
  if [[ ${REASSIGNMENT_SCOPE?} == setup_file ]]; then
    assert_variables_are_readonly
  fi
}

@test "variables are readonly" {
  if [[ ${REASSIGNMENT_SCOPE?} == test ]]; then
    assert_variables_are_readonly
  fi
}
