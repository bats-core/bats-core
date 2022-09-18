#!/usr/bin/bash

get_pr_json() {
  curl -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/bats-core/bats-core/pulls/$1"
}

PR_NUMBER="$1"
LABEL="$2"

get_pr_json "$PR_NUMBER" | jq .labels[].name | grep "$LABEL"
