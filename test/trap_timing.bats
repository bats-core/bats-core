#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load test_helper
fixtures trap_timing

@test "timeout watchdog does not leave its sleep process running" {
  local sleep_pid_file="$BATS_TEST_TMPDIR/sleep-pid"

  # shellcheck disable=SC2016 # The script is expanded by the nested Bash.
  run env \
    BASH_ENV="$FIXTURE_ROOT/fault_injection.bash" \
    BATS_FAULT_SCRIPT=bats-exec-test \
    BATS_FAULT_COMMAND='trap*TERM' \
    BATS_FAULT_REQUIRE_RUNNING_JOB=1 \
    BATS_FAULT_CAPTURE=RUNNING_JOB \
    BATS_FAULT_CAPTURE_FILE="$sleep_pid_file" \
    BATS_FAULT_ACTION=TERM-current-shell \
    BATS_TEST_TIMEOUT=10 \
    bash -c '
      "$1" "$2" >"$3/nested-bats-output" 2>&1 &
      bats_pid=$!

      for _ in {1..100}; do
        [[ -s $4 ]] && break
        kill -0 "$bats_pid" 2>/dev/null || break
        sleep 0.01
      done

      # If the trap is installed before sleep starts, there is no vulnerable
      # running job at which to inject the signal.
      if [[ ! -s $4 ]]; then
        wait "$bats_pid"
        exit $?
      fi

      read -r sleep_pid <"$4"
      sleep_was_running=
      if kill -0 "$sleep_pid" 2>/dev/null; then
        sleep_was_running=1
        kill -KILL "$sleep_pid" 2>/dev/null || true
      fi

      wait "$bats_pid"
      bats_status=$?
      printf "nested Bats status: %s\n" "$bats_status"
      printf "sleep process %s survived watchdog termination: %s\n" \
        "$sleep_pid" "${sleep_was_running:-no}"
      [[ $bats_status -eq 0 && -z $sleep_was_running ]]
    ' _ "$BATS_ROOT/bin/bats" "$BATS_TEST_DIRNAME/fixtures/bats/passing.bats" \
    "$BATS_TEST_TMPDIR" "$sleep_pid_file"

  echo "$output"
  [ "$status" -eq 0 ]
}

@test "timeout watchdog is cleaned up if setup is interrupted" {
  local timeout=3
  SECONDS=0

  run env \
    BASH_ENV="$FIXTURE_ROOT/fault_injection.bash" \
    BATS_FAULT_SCRIPT=bats-exec-test \
    BATS_FAULT_COMMAND='BATS_TEST_COMPLETED=' \
    BATS_FAULT_ACTION=exit \
    BATS_TEST_TIMEOUT=$timeout \
    "$BATS_ROOT/bin/bats" "$BATS_TEST_DIRNAME/fixtures/bats/passing.bats"

  echo "elapsed: $SECONDS seconds"
  ((SECONDS < timeout))
}
