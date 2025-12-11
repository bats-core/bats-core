# shellcheck shell=bash

function setup_suite() {
  true
}

teardown_suite() {
  echo "normal teardown_suite stdout"
  echo "# Hash teardown_suite stdout"
  echo "normal teardown_suite stderr" >&2
  echo "# Hash teardown_suite stderr" >&2
  echo "normal teardown_suite fd3" >&3
  echo "# Hash teardown_suite fd3" >&3
}
