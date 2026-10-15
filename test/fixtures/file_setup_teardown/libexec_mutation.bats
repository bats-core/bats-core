setup_file() {
  export BATS_LIBEXEC="$BATS_RUN_TMPDIR/missing-libexec" || true
}

@test "passing" {
  true
}
