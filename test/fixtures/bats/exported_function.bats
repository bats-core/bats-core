# see issue https://github.com/sstephenson/bats/issues/225

if exported_function; then
  a='a is set'
fi

@test "failing test" {
  echo "a='$a'"
  false
}
