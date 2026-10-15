setup_suite() {
  export BATS_LIBEXEC="$BATS_RUN_TMPDIR/missing-libexec" || true
}
