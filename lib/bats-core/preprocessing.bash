if [[ -z "$TMPDIR" ]]; then
  BATS_TMPDIR='/tmp'
else
  BATS_TMPDIR="${TMPDIR%/}"
fi

BATS_TMPNAME="$BATS_TMPDIR/bats.$$"
BATS_PARENT_TMPNAME="$BATS_TMPDIR/bats.$PPID"
BATS_OUT="${BATS_TMPNAME}.out"

bats_preprocess_source() {
  BATS_TEST_SOURCE="${BATS_TMPNAME}.src"
  bats-preprocess "$BATS_TEST_FILENAME" >"$BATS_TEST_SOURCE"
  trap 'bats_cleanup_preprocessed_source' ERR EXIT
  trap 'bats_cleanup_preprocessed_source; exit 1' INT
}

bats_cleanup_preprocessed_source() {
  rm -f "$BATS_TEST_SOURCE"
}

bats_evaluate_preprocessed_source() {
  if [[ -z "$BATS_TEST_SOURCE" ]]; then
    BATS_TEST_SOURCE="${BATS_PARENT_TMPNAME}.src"
  fi
  source "$BATS_TEST_SOURCE"
}