do_recurse() {
  local value="$1"
  if [[ "$value" -eq 0 ]]; then
    return
  else
    # These statements validate that the first one isn't misinterpreted by
    # bats_debug_trap as a failing command, since $? will be 1 and BASH_COMMAND
    # will look identical, but on two successive lines.
    printf 'Recursing...\n'
    printf 'Recursing...\n'
    do_recurse "$((--value))"
  fi
}

@test "traced test case with recursion" {
  do_recurse 2
  :
}
