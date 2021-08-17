fun() {
  echo "$1"
  if [[ $1 -gt 0 ]]; then
    fun $(($1 - 1))
  fi
}

@test "a recursive failing test" {
  echo Outer
  fun 2
  run fun 2
  false
}
