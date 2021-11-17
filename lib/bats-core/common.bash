#!/usr/bin/env bash

bats_prefix_lines_for_tap_output() {
    while IFS= read -r line; do
      printf '# %s\n' "$line" || break # avoid feedback loop when errors are redirected into BATS_OUT (see #353)
    done
    if [[ -n "$line" ]]; then
      printf '# %s\n' "$line"
    fi
}

bats_quote_code() { # <var> <code>
	printf -v "$1" -- "%s%s%s" "$BATS_BEGIN_CODE_QUOTE" "$2" "$BATS_END_CODE_QUOTE"
}
