#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

bats_encode_test_name() {
  local name="$1"
  local result='test_'
  local hex_code

  if [[ ! "$name" =~ [^[:alnum:]\ _-] ]]; then
    name="${name//_/-5f}"
    name="${name//-/-2d}"
    name="${name// /_}"
    result+="$name"
  else
    local length="${#name}"
    local char i

    for ((i = 0; i < length; i++)); do
      char="${name:$i:1}"
      if [[ "$char" == ' ' ]]; then
        result+='_'
      elif [[ "$char" =~ [[:alnum:]] ]]; then
        result+="$char"
      else
        printf -v 'hex_code' -- '-%02x' \'"$char"
        result+="$hex_code"
      fi
    done
  fi

  printf -v "$2" '%s' "$result"
}

bats_decode_test_name() {
  local name="$1"
  local length="${#name}"
  name="${name#test_}"
  local i=0
  local result=''
  local char=''
  while (( i < length )); do
    char="${name:$i:1}"
    case $char in
      '-')
        (( i += 1 ))
        if [[ "${name:$i:4}" == '2d5f' ]]; then
          result+="_"
          (( i += 4 ))
        else
          result+=$(printf "%b" "\x${name:$i:2}")
          (( i += 2 ))
        fi
      ;;
      '_')
        result+=" "
        (( i += 1 ))
        ;;
      *)
        result+="$char"
        (( i += 1 ))
    ;;
    esac
  done
  printf -v "$2" '%s' "$result"
}

# bats test_tags=bats:slow
@test "decode" {
  BATS_TEST_PATTERN="^[[:blank:]]*@test[[:blank:]]+(.*[^[:blank:]])[[:blank:]]+\{(.*)\$"
  local count=0
  local encoded decoded
  while read -r line; do
    if [[ "$line" =~ $BATS_TEST_PATTERN ]]; then
      (( count += 1 ))
      name="${BASH_REMATCH[1]#[\'\"]}"
      name="${name%[\'\"]}"
      bats_encode_test_name "$name" 'encoded'
      bats_decode_test_name "$encoded" 'decoded'
      [[ "$name" == "$decoded" ]]
    fi
  done < <(find "$BATS_ROOT"/test/fixtures/list_test_names -type f -name '*.bats' -print0 | xargs -0 grep -h '^@test')
}
