@test "double bracket returns false" {
  local value='true'
  [[ "$value" == 'true' ]]
  [[ "$value" == 'false' ]]
}
