@test "failing" {
  if [[ -z "${DONT_ABORT:-}" ]]; then
    # emulate CTRL-C by sending SIGINT to the whole process group
    kill -SIGINT -- -"$BATS_ROOT_PID"
  fi
  false
}

@test "passing" {
  :
}
