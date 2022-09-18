setup_file() {
  [ "$EXPORTED_VAR" = "$EXPECTED_VALUE" ]
}

setup() {
  [ "$EXPORTED_VAR" = "$EXPECTED_VALUE" ]
}

@test test {
  [ "$EXPORTED_VAR" = "$EXPECTED_VALUE" ]
}
