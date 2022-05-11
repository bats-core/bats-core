#!/usr/bin/env bash

bats_prefix_lines_for_tap_output() {
    while IFS= read -r line; do
      printf '# %s\n' "$line" || break # avoid feedback loop when errors are redirected into BATS_OUT (see #353)
    done
    if [[ -n "$line" ]]; then
      printf '# %s\n' "$line"
    fi
}

function bats_replace_filename() {
  local line
  while read -r line; do
    printf "%s\n" "${line//$BATS_TEST_SOURCE/$BATS_TEST_FILENAME}"
  done
  if [[ -n "$line" ]]; then
    printf "%s\n" "${line//$BATS_TEST_SOURCE/$BATS_TEST_FILENAME}"
  fi
}

bats_quote_code() { # <var> <code>
	printf -v "$1" -- "%s%s%s" "$BATS_BEGIN_CODE_QUOTE" "$2" "$BATS_END_CODE_QUOTE"
}

bats_check_valid_version() {
  if [[ ! $1 =~ [0-9]+.[0-9]+.[0-9]+ ]]; then
    printf "ERROR: version '%s' must be of format <major>.<minor>.<patch>!\n" "$1" >&2
    exit 1
  fi
}

# compares two versions. Return 0 when version1 < version2
bats_version_lt() { # <version1> <version2>
  bats_check_valid_version "$1"
  bats_check_valid_version "$2"

  local -a version1_parts version2_parts
  IFS=. read -ra version1_parts <<< "$1"
  IFS=. read -ra version2_parts <<< "$2"

  for i in {0..2}; do
    if (( version1_parts[i] < version2_parts[i] )); then
      return 0
    elif (( version1_parts[i] > version2_parts[i] )); then
      return 1
    fi
  done
  # if we made it this far, they are equal -> also not less then
  return 2 # use other failing return code to distinguish equal from gt
}

# ensure a minimum version of bats is running or exit with failure
bats_require_minimum_version() { # <required version>
  local required_minimum_version=$1

  if bats_version_lt "$BATS_VERSION" "$required_minimum_version"; then
    printf "BATS_VERSION=%s does not meet required minimum %s\n" "$BATS_VERSION" "$required_minimum_version"
    exit 1
  fi

  if bats_version_lt "$BATS_GUARANTEED_MINIMUM_VERSION" "$required_minimum_version"; then
    BATS_GUARANTEED_MINIMUM_VERSION="$required_minimum_version"
  fi
}
