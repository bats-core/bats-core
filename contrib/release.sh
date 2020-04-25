#!/usr/bin/env bash
#
# bats-core git releaser
#
## Usage: %SCRIPT_NAME% [options]
##
## Options:
##   --major            Major version bump
##   --minor            Minor version bump
##   --patch            Patch version bump
##
##   -v, --version      Print version
##   --debug            Enable debug mode
##   -h, --help         Display this message
##

set -Eeuo pipefail

DIR=$(cd "$(dirname "${0}")" && pwd)
THIS_SCRIPT="${DIR}/$(basename "${0}")"
BATS_VERSION=$(
  # shellcheck disable=SC1090
  source <(grep '^export BATS_VERSION=' libexec/bats-core/bats)
  echo "${BATS_VERSION}"
)
declare -r DIR
declare -r THIS_SCRIPT
declare -r BATS_VERSION

BUMP_INTERVAL=""
NEW_BATS_VERSION=""

main() {
  handle_arguments "${@}"

  if [[ "${BUMP_INTERVAL:-}" == "" ]]; then
    echo "${BATS_VERSION}"
    exit 0
  fi

  local NEW_BATS_VERSION
  NEW_BATS_VERSION=$(semver bump "${BUMP_INTERVAL}" "${BATS_VERSION}")
  declare -r NEW_BATS_VERSION

  echo "Releasing: ${BATS_VERSION} to ${NEW_BATS_VERSION}"
  echo

  replace_in_files

  write_changelog

  git diff --staged

  cat <<EOF
# To complete the release:

git commit -m "feat: release Bats ${NEW_BATS_VERSION}"

git tag -a -s "${NEW_BATS_VERSION}"
# Include the docs/CHANGELOG.md notes corresponding to the new version as the
# tag annotation, except the first line should be: Bats ${NEW_BATS_VERSION} - $(date +%Y-%m-%d)
# and any Markdown headings should become plain text

git push --follow-tags

# navigate to https://github.com/bats-core/bats-core/releases and follow
# instuctions in docs/releasing.md
# - Name the release: Bats ${NEW_BATS_VERSION}
# - Paste the same notes from the version tag annotation as the description,
#   except change the first line to read: Released: $(date +%Y-%m-%d).
EOF

  exit 0
}

replace_in_files() {
  declare -a FILE_REPLACEMENTS=(
    ".appveyor.yml,^version:"
    "contrib/rpm/bats.spec,^Version:"
    "libexec/bats-core/bats,^export BATS_VERSION="
    "package.json,^  \"version\":"
  )

  for FILE_REPLACEMENT in "${FILE_REPLACEMENTS[@]}"; do
    FILE="${FILE_REPLACEMENT/,*/}"
    MATCH="${FILE_REPLACEMENT/*,/}"
    sed -E -i.bak "/${MATCH}/ { s,${BATS_VERSION},${NEW_BATS_VERSION},g; }" "${FILE}"
    rm "${FILE}.bak" || true
    git add -f "${FILE}"
  done
}

write_changelog() {
  local FILE="docs/CHANGELOG.md"
  sed -E -i.bak "/## \[Unreleased\]/ a \\\n## [${NEW_BATS_VERSION}] - $(date +%Y-%m-%d)" "${FILE}"

  rm "${FILE}.bak" || true

  cp "${FILE}" "${FILE}.new"
  sed -E -i.bak '/## \[Unreleased\]/,+1d' "${FILE}"
  git add -f "${FILE}"
  mv "${FILE}.new" "${FILE}"
}

handle_arguments() {
  parse_arguments "${@:-}"
}

parse_arguments() {
  local CURRENT_ARG

  if [[ "${#}" == 1 && "${1:-}" == "" ]]; then
    return 0
  fi

  while [[ "${#}" -gt 0 ]]; do
    CURRENT_ARG="${1}"

    case ${CURRENT_ARG} in
    --major)
      BUMP_INTERVAL="major"
      ;;
    # ---
    --minor)
      BUMP_INTERVAL="minor"
      ;;
    --patch)
      BUMP_INTERVAL="patch"
      ;;
    -h | --help) usage ;;
    -v | --version)
      get_version
      exit 0
      ;;
    --debug)
      set -xe
      ;;
    -*) usage "${CURRENT_ARG}: unknown option" ;;
    esac
    shift
  done
}

semver() {
  "${DIR}/semver" "${@:-}"
}

usage() {
  sed -n '/^##/,/^$/s/^## \{0,1\}//p' "${THIS_SCRIPT}" | sed "s/%SCRIPT_NAME%/$(basename "${THIS_SCRIPT}")/g"
  exit 2
} 2>/dev/null

get_version() {
  echo "${THIS_SCRIPT_VERSION:-0.1}"
}

main "${@}"
