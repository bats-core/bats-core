#!/usr/bin/env bash

setup() {
  echo "GH Test: ${BATS_TEST_DESCRIPTION}" > /tmp/ghtestfile
}

teardown() {
  rm -f /tmp/ghtestfile
}
