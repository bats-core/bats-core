@test "BATS_BUCKET is initially an empty string" {
  run declare -p BATS_BUCKET

  BATS_BUCKET='value'

  [ "${lines[0]}" == 'declare -x BATS_BUCKET=""' ]
}

@test "value is passed between tests" {
  [ "$BATS_BUCKET" == 'value' ]
}
