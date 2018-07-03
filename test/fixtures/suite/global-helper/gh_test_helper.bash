#!/usr/bin/env bash

setup() {
  echo "GH Test: ${BATS_TEST_DESCRIPTION}" > ${BATS_TEST_SUITE_TMPDIR}/ghtestfile
}

teardown() {
  rm -f ${BATS_TEST_SUITE_TMPDIR}/ghtestfile
}
