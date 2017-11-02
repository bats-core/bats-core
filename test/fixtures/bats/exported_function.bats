# see issue https://github.com/sstephenson/bats/issues/225

@test "failing test" {
  if exported_function; then
    a='exported_function'
  fi
  echo "a='$a'"
  false
}
