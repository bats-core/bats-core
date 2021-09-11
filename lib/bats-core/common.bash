#!/usr/bin/env bash

bats_prefix_lines_for_tap_output() {
    while IFS= read -r line; do
      printf '# %s\n' "$line" || break # avoid feedback loop when errors are redirected into BATS_OUT (see #353)
    done
    if [[ -n "$line" ]]; then
      printf '# %s\n' "$line"
    fi
}