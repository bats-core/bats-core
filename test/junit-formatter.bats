#!/usr/bin/env bats

load test_helper
fixtures junit-formatter

FLOAT_REGEX='[0-9]+(\.[0-9]+){0,1}'
TIMESTAMP_REGEX='[0-9]+-[0-1][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]'
TESTSUITES_REGEX="<testsuites time=\"$FLOAT_REGEX\">"

@test "junit formatter with skipped test does not fail" {
  run bats --formatter junit "$FIXTURE_ROOT/skipped.bats"
  echo "$output"
  [[ $status -eq 0 ]]
  [[ "${lines[0]}" == '<?xml version="1.0" encoding="UTF-8"?>' ]]
  
  [[ "${lines[1]}" =~ $TESTSUITES_REGEX ]]

  TESTSUITE_REGEX="<testsuite name=\"skipped.bats\" tests=\"2\" failures=\"0\" errors=\"0\" skipped=\"2\" time=\"$FLOAT_REGEX\" timestamp=\"$TIMESTAMP_REGEX\" hostname=\".*\">"
  echo "TESTSUITE_REGEX='$TESTSUITE_REGEX'"
  [[ "${lines[2]}" =~ $TESTSUITE_REGEX ]]

  TESTCASE_REGEX="<testcase classname=\"skipped.bats\" name=\"a skipped test\" time=\"$FLOAT_REGEX\">"
  [[ "${lines[3]}" =~ $TESTCASE_REGEX ]]

  [[ "${lines[4]}" == *"<skipped></skipped>"* ]]
  [[ "${lines[5]}" == *"</testcase>"* ]]

  TESTCASE_REGEX="<testcase classname=\"skipped.bats\" name=\"a skipped test with a reason\" time=\"$FLOAT_REGEX\">"
  [[ "${lines[6]}" =~ $TESTCASE_REGEX ]]
  [[ "${lines[7]}" == *"<skipped>a reason</skipped>"* ]]
  [[ "${lines[8]}" == *"</testcase>"* ]]
  
  [[ "${lines[9]}" == *"</testsuite>"* ]]
  [[ "${lines[10]}" == *"</testsuites>"* ]]
}

@test "junit formatter: escapes xml special chars" {
  make_bats_test_suite_tmpdir
  case $OSTYPE in
    linux*|darwin)
      # their CI can handle special chars on filename
      TEST_FILE_NAME="xml-escape-\"<>'&.bats"
      ESCAPED_TEST_FILE_NAME="xml-escape-&quot;&lt;&gt;&#39;&amp;.bats"
      TEST_FILE_PATH="$BATS_TEST_SUITE_TMPDIR/$TEST_FILE_NAME"
      cp "$FIXTURE_ROOT/xml-escape.bats" "$TEST_FILE_PATH"
      NEED_CLEANUP=1
    ;;
    *)
      # use the filename without special chars
      TEST_FILE_NAME="xml-escape.bats"
      ESCAPED_TEST_FILE_NAME="$TEST_FILE_NAME"
      TEST_FILE_PATH="$FIXTURE_ROOT/$TEST_FILE_NAME"
    ;;
  esac
  run bats --formatter junit "$TEST_FILE_PATH"
  [[ ${NEED_CLEANUP-0} == 0 ]] || rm "$TEST_FILE_PATH" # clean up to avoid leaving local file

  echo "$output"
  TESTSUITE_REGEX="<testsuite name=\"$ESCAPED_TEST_FILE_NAME\" tests=\"3\" failures=\"1\" errors=\"0\" skipped=\"1\" time=\"$FLOAT_REGEX\" timestamp=\"$TIMESTAMP_REGEX\" hostname=\".*\">"
  [[ "${lines[2]}" =~ $TESTSUITE_REGEX ]]
  TESTCASE_REGEX="<testcase classname=\"$ESCAPED_TEST_FILE_NAME\" name=\"Successful test with escape characters: &quot;&#39;&lt;&gt;&amp;&#27;\(0x1b\)\" time=\"$FLOAT_REGEX\"/>"
  [[ "${lines[3]}" =~ $TESTCASE_REGEX ]]
  [[ "${lines[7]}" == *'`echo &quot;&lt;&gt;&#39;&amp;&#27;&quot; &amp;&amp; false&#39; failed'* ]]

  TESTCASE_REGEX="<testcase classname=\"$ESCAPED_TEST_FILE_NAME\" name=\"Skipped test with escape characters: &quot;&#39;&lt;&gt;&amp;&#27;\(0x1b\)\" time=\"$FLOAT_REGEX\">"
  [[ "${lines[10]}" =~ $TESTCASE_REGEX ]]

  TESTCASE_REGEX="<skipped>&quot;&#39;&lt;&gt;&amp;&#27;</skipped>"
  [[ "${lines[11]}" =~ $TESTCASE_REGEX ]]
}

@test "junit formatter: test suites" {
  run bats --formatter junit "$FIXTURE_ROOT/suite/"
  echo "$output"

  [[ "${lines[0]}" == '<?xml version="1.0" encoding="UTF-8"?>' ]]
  [[ "${lines[1]}" == *"<testsuites "* ]]
  [[ "${lines[2]}" == *"<testsuite name=\"file1.bats\""* ]]
  [[ "${lines[3]}" == *"<testcase "* ]]
  [[ "${lines[4]}" == *"</testsuite>"* ]]
  [[ "${lines[5]}" == *"<testsuite name=\"file2.bats\""* ]]
  [[ "${lines[6]}" == *"<testcase"* ]]
  [[ "${lines[7]}" == *"</testsuite>"* ]]
  [[ "${lines[8]}" == *"</testsuites>"* ]]
}

@test "junit formatter: test suites relative path" {
  cd "$FIXTURE_ROOT"
  run bats --formatter junit "suite/"
  echo "$output"

  [[ "${lines[0]}" == '<?xml version="1.0" encoding="UTF-8"?>' ]]
  [[ "${lines[1]}" == *"<testsuites "* ]]
  [[ "${lines[2]}" == *"<testsuite name=\"file1.bats\""* ]]
  [[ "${lines[3]}" == *"<testcase "* ]]
  [[ "${lines[4]}" == *"</testsuite>"* ]]
  [[ "${lines[5]}" == *"<testsuite name=\"file2.bats\""* ]]
  [[ "${lines[6]}" == *"<testcase"* ]]
  [[ "${lines[7]}" == *"</testsuite>"* ]]
  [[ "${lines[8]}" == *"</testsuites>"* ]]
}

@test "junit formatter: files with the same name are distinguishable" {
  run bats --formatter junit -r "$FIXTURE_ROOT/duplicate/"
  echo "$output"

  [[ "${lines[2]}" == *"<testsuite name=\"first/file1.bats\""* ]]
  [[ "${lines[5]}" == *"<testsuite name=\"second/file1.bats\""* ]]
}