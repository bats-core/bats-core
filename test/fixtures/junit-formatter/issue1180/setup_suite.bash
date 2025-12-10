# shellcheck shell=bash

function setup_suite() {
  true
}

teardown_suite() {
  echo "Teardown_suite stdout"
  echo "# Hash teardown_suite stdout"
  echo "Teardown_suite stderr" >&2
  echo "# Hash teardown_suite stderr" >&2
  echo "Teardown_suite fd3" >&3
  echo "# Hash teardown_suite fd3" >&3
}
