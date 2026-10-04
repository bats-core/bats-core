#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load test_helper

@test "semaphore cleanup trap preserves the command status" {
  run bash -c '
    set -e
    source "$1"

    output_dir=$2/output
    BATS_SEMAPHORE_DIR=$2/semaphores
    mkdir -p "$BATS_SEMAPHORE_DIR/slot-0"

    run_with_caller_status() {
      local status=0
      bats_semaphore_release_wrapper "$output_dir" 0 false
    }

    run_with_caller_status
  ' _ "$BATS_ROOT/$BATS_LIBDIR/bats-core/semaphore.bash" "$BATS_TEST_TMPDIR"

  echo "semaphore wrapper status: $status"
  [ "$status" -eq 1 ]
}
