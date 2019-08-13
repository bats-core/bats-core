#!/usr/bin/env bats

TEST_REPORT_FILE="TestReport-skipped.bats.xml"

teardown() {
    rm  "$TEST_REPORT_FILE"
}

@test "skipped-test-results-in-success-type" {
    bats --formatter junit "$BATS_ROOT/test/fixtures/bats/skipped.bats"

    run grep -A 1 'name="a skipped test"' $TEST_REPORT_FILE
    echo "Skipped test without reason: '${lines[1]}'"
    [[ ${lines[1]} == *"<skipped></skipped>"* ]]

    run grep -A 1 'name="a skipped test with a reason"' $TEST_REPORT_FILE
    echo "Skiped test with reason: ${lines[1]}"
    [[ ${lines[1]} == *"<skipped>a reason</skipped>"* ]]
}