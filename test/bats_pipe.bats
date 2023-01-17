load test_helper
fixtures run
bats_require_minimum_version 1.5.0

#########
# Test Helpers

describe_args() {
  echo "Got $# args."

  while [ $# -gt 0 ]; do
    echo "arg: $1"
    shift
  done
}

describe_input() {
  describe_args "$@"

  local given_stdin=
  read -rd $'\0' -t 1 given_stdin
  if [ -n "$given_stdin" ]; then
    echo 'stdin:'
    local _oldIFS="$IFS"
    IFS=$'\n'
    printf '\t%s\n' "$given_stdin"
    IFS="$_oldIFS"
  fi
}

returns_with_given_code() {
  echo "Will return status $1."

  return "$1"
}

# Necessary to prevent SIGPIPE error.
consume_stdin_and_returns_with_given_code() {
  echo "Will return status $1."

  local unused=
  # ignore unused.
  # shellcheck disable=2162
  read -d $'\0' -t 1 unused

  return "$1"
}

output_binary_data_and_returns_with_given_code() {
  printf '\x00\xDE\xAD\xF0\x0D'

  return "$1"
}

#########
# Tests

@test "run bats_pipe with no commands" {
  run bats_pipe

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: No \`\\|\`s found. Is this an error?" ]
}

@test "run bats_pipe with single command with no args" {
  run bats_pipe describe_args

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: No \`\\|\`s found. Is this an error?" ]
}

@test "run bats_pipe with single command with no args with arg separator" {
  run bats_pipe -- describe_args

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: No \`\\|\`s found. Is this an error?" ]
}

@test "run bats_pipe with single command with one arg" {
  run bats_pipe describe_args a

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: No \`\\|\`s found. Is this an error?" ]
}

@test "run bats_pipe with single command with two args" {
  run bats_pipe describe_args a b

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: No \`\\|\`s found. Is this an error?" ]
}

@test "run bats_pipe with single command with two args with arg separator" {
  run bats_pipe -- describe_args a b

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: No \`\\|\`s found. Is this an error?" ]
}

@test "run bats_pipe piping between two command with zero and zero args" {
  run bats_pipe describe_args \| describe_input

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tGot 0 args.' ]
}

@test "run bats_pipe piping between two command with zero and zero args with arg separator" {
  run bats_pipe -- describe_args \| describe_input

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tGot 0 args.' ]
}

@test "run bats_pipe piping between two command with zero and one args" {
  run bats_pipe describe_args \| describe_input a

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 4 ]
  [ "${lines[0]}" = 'Got 1 args.' ]
  [ "${lines[1]}" = 'arg: a' ]
  [ "${lines[2]}" = 'stdin:' ]
  [ "${lines[3]}" = $'\tGot 0 args.' ]
}

@test "run bats_pipe piping between two command with zero and two args" {
  run bats_pipe describe_args \| describe_input a b

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 5 ]
  [ "${lines[0]}" = 'Got 2 args.' ]
  [ "${lines[1]}" = 'arg: a' ]
  [ "${lines[2]}" = 'arg: b' ]
  [ "${lines[3]}" = 'stdin:' ]
  [ "${lines[4]}" = $'\tGot 0 args.' ]
}

@test "run bats_pipe piping between two command with zero and two args with arg separator" {
  run bats_pipe -- describe_args \| describe_input a b

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 5 ]
  [ "${lines[0]}" = 'Got 2 args.' ]
  [ "${lines[1]}" = 'arg: a' ]
  [ "${lines[2]}" = 'arg: b' ]
  [ "${lines[3]}" = 'stdin:' ]
  [ "${lines[4]}" = $'\tGot 0 args.' ]
}

@test "run bats_pipe piping between two command with one and zero args" {
  run bats_pipe describe_args a \| describe_input

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 4 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tGot 1 args.' ]
  [ "${lines[3]}" = $'\targ: a' ]
}

@test "run bats_pipe piping between two command with one and zero args with arg separator" {
  run bats_pipe -- describe_args a \| describe_input

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 4 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tGot 1 args.' ]
  [ "${lines[3]}" = $'\targ: a' ]
}

@test "run bats_pipe piping between two command with one and one args" {
  run bats_pipe describe_args a \| describe_input b

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 5 ]
  [ "${lines[0]}" = 'Got 1 args.' ]
  [ "${lines[1]}" = 'arg: b' ]
  [ "${lines[2]}" = 'stdin:' ]
  [ "${lines[3]}" = $'\tGot 1 args.' ]
  [ "${lines[4]}" = $'\targ: a' ]
}

@test "run bats_pipe piping between two command with one and two args" {
  run bats_pipe describe_args a \| describe_input b c

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 6 ]
  [ "${lines[0]}" = 'Got 2 args.' ]
  [ "${lines[1]}" = 'arg: b' ]
  [ "${lines[2]}" = 'arg: c' ]
  [ "${lines[3]}" = 'stdin:' ]
  [ "${lines[4]}" = $'\tGot 1 args.' ]
  [ "${lines[5]}" = $'\targ: a' ]
}

@test "run bats_pipe piping between two command with two and zero args" {
  run bats_pipe describe_args a b \| describe_input

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 5 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tGot 2 args.' ]
  [ "${lines[3]}" = $'\targ: a' ]
  [ "${lines[4]}" = $'\targ: b' ]
}

@test "run bats_pipe piping between two command with two and one args" {
  run bats_pipe describe_args a b \| describe_input c

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 6 ]
  [ "${lines[0]}" = 'Got 1 args.' ]
  [ "${lines[1]}" = 'arg: c' ]
  [ "${lines[2]}" = 'stdin:' ]
  [ "${lines[3]}" = $'\tGot 2 args.' ]
  [ "${lines[4]}" = $'\targ: a' ]
  [ "${lines[5]}" = $'\targ: b' ]
}

@test "run bats_pipe piping between two command with two and two args" {
  run bats_pipe describe_args a b \| describe_input c d

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 7 ]
  [ "${lines[0]}" = 'Got 2 args.' ]
  [ "${lines[1]}" = 'arg: c' ]
  [ "${lines[2]}" = 'arg: d' ]
  [ "${lines[3]}" = 'stdin:' ]
  [ "${lines[4]}" = $'\tGot 2 args.' ]
  [ "${lines[5]}" = $'\targ: a' ]
  [ "${lines[6]}" = $'\targ: b' ]
}

@test "run bats_pipe piping between three command with zero args each" {
  run bats_pipe describe_args \| describe_input \| describe_input

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 5 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tGot 0 args.' ]
  [ "${lines[3]}" = $'\tstdin:' ]
  [ "${lines[4]}" = $'\t\tGot 0 args.' ]
}

@test "run bats_pipe piping between three command with one arg each" {
  run bats_pipe describe_args a \| describe_input b \| describe_input c

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 8 ]
  [ "${lines[0]}" = 'Got 1 args.' ]
  [ "${lines[1]}" = 'arg: c' ]
  [ "${lines[2]}" = 'stdin:' ]
  [ "${lines[3]}" = $'\tGot 1 args.' ]
  [ "${lines[4]}" = $'\targ: b' ]
  [ "${lines[5]}" = $'\tstdin:' ]
  [ "${lines[6]}" = $'\t\tGot 1 args.' ]
  [ "${lines[7]}" = $'\t\targ: a' ]
}

@test "run bats_pipe piping between three command with one arg each with arg separator" {
  run bats_pipe -- describe_args a \| describe_input b \| describe_input c

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 8 ]
  [ "${lines[0]}" = 'Got 1 args.' ]
  [ "${lines[1]}" = 'arg: c' ]
  [ "${lines[2]}" = 'stdin:' ]
  [ "${lines[3]}" = $'\tGot 1 args.' ]
  [ "${lines[4]}" = $'\targ: b' ]
  [ "${lines[5]}" = $'\tstdin:' ]
  [ "${lines[6]}" = $'\t\tGot 1 args.' ]
  [ "${lines[7]}" = $'\t\targ: a' ]
}

@test "run bats_pipe piping between three command with two args each" {
  run bats_pipe describe_args a b \| describe_input c d \| describe_input e f

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 11 ]
  [ "${lines[0]}" = 'Got 2 args.' ]
  [ "${lines[1]}" = 'arg: e' ]
  [ "${lines[2]}" = 'arg: f' ]
  [ "${lines[3]}" = 'stdin:' ]
  [ "${lines[4]}" = $'\tGot 2 args.' ]
  [ "${lines[5]}" = $'\targ: c' ]
  [ "${lines[6]}" = $'\targ: d' ]
  [ "${lines[7]}" = $'\tstdin:' ]
  [ "${lines[8]}" = $'\t\tGot 2 args.' ]
  [ "${lines[9]}" = $'\t\targ: a' ]
  [ "${lines[10]}" = $'\t\targ: b' ]
}

@test "run bats_pipe with leading | on single command" {
  run bats_pipe \| describe_args

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: Cannot have leading \`\\|\`." ]
}

@test "run bats_pipe with leading | on two piped commands" {
  run bats_pipe \| describe_args \| describe_input

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: Cannot have leading \`\\|\`." ]
}

@test "run bats_pipe with trailing | on single command" {
  run bats_pipe describe_args \|

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: Cannot have trailing \`\\|\`." ]
}

@test "run bats_pipe with trailing | on two piped commands" {
  run bats_pipe describe_args \| describe_input \|

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: Cannot have trailing \`\\|\`." ]
}

@test "run bats_pipe with consecutive |s after single command" {
  run bats_pipe describe_args \| \|

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: Cannot have consecutive \`\\|\`. Found at argument position '2'." ]
}

@test "run bats_pipe with consecutive |s between two piped commands" {
  run bats_pipe describe_args \| \| describe_input

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: Cannot have consecutive \`\\|\`. Found at argument position '2'." ]
}

@test "run bats_pipe with consecutive |s after two piped commands" {
  run bats_pipe describe_args \| describe_input \| \|

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: Cannot have consecutive \`\\|\`. Found at argument position '4'." ]
}

@test "run bats_pipe with consecutive |s between first pair of three piped commands" {
  run bats_pipe describe_args \| \| describe_input \| describe_input

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: Cannot have consecutive \`\\|\`. Found at argument position '2'." ]
}

@test "run bats_pipe with consecutive |s between second pair of three piped commands" {
  run bats_pipe describe_args \| describe_input \| \| describe_input

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: Cannot have consecutive \`\\|\`. Found at argument position '4'." ]
}

@test "run bats_pipe with consecutive |s after three piped commands" {
  run bats_pipe describe_args \| describe_input \| describe_input \| \|

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: Cannot have consecutive \`\\|\`. Found at argument position '6'." ]
}

@test "run bats_pipe with unknown arg" {
  run bats_pipe --idklol describe_args

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: unknown flag '--idklol'" ]
}

@test "run bats_pipe for last error status and fail on first of two" {
  run bats_pipe returns_with_given_code 42 \| describe_input

  [ "$status" -eq 42 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tWill return status 42.' ]
}

@test "run bats_pipe for last error status and fail on second of two" {
  run bats_pipe returns_with_given_code 0 \| consume_stdin_and_returns_with_given_code 84

  [ "$status" -eq 84 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = $'Will return status 84.' ]
}

@test "run bats_pipe for last error status and fail on both of two" {
  run bats_pipe returns_with_given_code 42 \| consume_stdin_and_returns_with_given_code 84

  [ "$status" -eq 84 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = 'Will return status 84.' ]
}

@test "run bats_pipe for last error status and fail on first of three" {
  run bats_pipe returns_with_given_code 42 \| describe_input \| describe_input

  [ "$status" -eq 42 ]
  [ "${#lines[@]}" -eq 5 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tGot 0 args.' ]
  [ "${lines[3]}" = $'\tstdin:' ]
  [ "${lines[4]}" = $'\t\tWill return status 42.' ]
}

@test "run bats_pipe for last error status and fail on second of three" {
  run bats_pipe returns_with_given_code 0 \| consume_stdin_and_returns_with_given_code 42 \| describe_input

  [ "$status" -eq 42 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tWill return status 42.' ]
}

@test "run bats_pipe for last error status and fail on third of three" {
  run bats_pipe returns_with_given_code 0 \| consume_stdin_and_returns_with_given_code 0 \| consume_stdin_and_returns_with_given_code 42

  [ "$status" -eq 42 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = $'Will return status 42.' ]
}

@test "run bats_pipe for last error status and fail on first pair of three" {
  run bats_pipe returns_with_given_code 42 \| consume_stdin_and_returns_with_given_code 84 \| describe_input

  [ "$status" -eq 84 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tWill return status 84.' ]
}

@test "run bats_pipe for last error status and fail on second pair of three" {
  run bats_pipe returns_with_given_code 0 \| consume_stdin_and_returns_with_given_code 42 \| consume_stdin_and_returns_with_given_code 4

  [ "$status" -eq 4 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = $'Will return status 4.' ]
}

@test "run bats_pipe for last error status and fail on all of three" {
  run bats_pipe returns_with_given_code 42 \| consume_stdin_and_returns_with_given_code 84 \| consume_stdin_and_returns_with_given_code 4

  [ "$status" -eq 4 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = $'Will return status 4.' ]
}

@test "run bats_pipe for 0th error status and fail on first of two" {
  run bats_pipe -0 returns_with_given_code 42 \| describe_input

  [ "$status" -eq 42 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tWill return status 42.' ]
}

@test "run bats_pipe for 0th error status and fail on first of two with arg separator" {
  run bats_pipe -0 -- returns_with_given_code 42 \| describe_input

  [ "$status" -eq 42 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tWill return status 42.' ]
}

@test "run bats_pipe for 0th error status and fail on second of two" {
  run bats_pipe -0 returns_with_given_code 0 \| consume_stdin_and_returns_with_given_code 42

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = 'Will return status 42.' ]
}

@test "run bats_pipe for 0th error status and fail on both of two" {
  run bats_pipe -0 returns_with_given_code 42 \| consume_stdin_and_returns_with_given_code 84

  [ "$status" -eq 42 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = 'Will return status 84.' ]
}

@test "run bats_pipe for 0th error status and fail on first of three" {
  run bats_pipe -0 returns_with_given_code 42 \| describe_input \| describe_input

  [ "$status" -eq 42 ]
  [ "${#lines[@]}" -eq 5 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tGot 0 args.' ]
  [ "${lines[3]}" = $'\tstdin:' ]
  [ "${lines[4]}" = $'\t\tWill return status 42.' ]
}

@test "run bats_pipe for 0th error status and fail on second of three" {
  run bats_pipe -0 returns_with_given_code 0 \| consume_stdin_and_returns_with_given_code 42 \| describe_input

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tWill return status 42.' ]
}

@test "run bats_pipe for 0th error status and fail on third of three" {
  run bats_pipe -0 returns_with_given_code 0 \| consume_stdin_and_returns_with_given_code 0 \| consume_stdin_and_returns_with_given_code 42

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = 'Will return status 42.' ]
}

@test "run bats_pipe for 0th error status and fail on all of three" {
  run bats_pipe -0 returns_with_given_code 42 \| consume_stdin_and_returns_with_given_code 84 \| consume_stdin_and_returns_with_given_code 4

  [ "$status" -eq 42 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = 'Will return status 4.' ]
}

@test "run bats_pipe for 1st error status and fail on first of two" {
  run bats_pipe -1 returns_with_given_code 42 \| describe_input

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tWill return status 42.' ]
}

@test "run bats_pipe for 1st error status and fail on first of two with arg separator" {
  run bats_pipe -1 -- returns_with_given_code 42 \| describe_input

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tWill return status 42.' ]
}

@test "run bats_pipe for 1st error status and fail on second of two" {
  run bats_pipe -1 returns_with_given_code 0 \| consume_stdin_and_returns_with_given_code 42

  [ "$status" -eq 42 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = 'Will return status 42.' ]
}

@test "run bats_pipe for 1st error status and fail on both of two" {
  run bats_pipe -1 returns_with_given_code 42 \| consume_stdin_and_returns_with_given_code 84

  [ "$status" -eq 84 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = 'Will return status 84.' ]
}

@test "run bats_pipe for 1st error status and fail on first of three" {
  run bats_pipe -1 returns_with_given_code 42 \| describe_input \| describe_input

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 5 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tGot 0 args.' ]
  [ "${lines[3]}" = $'\tstdin:' ]
  [ "${lines[4]}" = $'\t\tWill return status 42.' ]
}

@test "run bats_pipe for 1st error status and fail on second of three" {
  run bats_pipe -1 returns_with_given_code 0 \| consume_stdin_and_returns_with_given_code 42 \| describe_input

  [ "$status" -eq 42 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tWill return status 42.' ]
}

@test "run bats_pipe for 1st error status and fail on third of three" {
  run bats_pipe -1 returns_with_given_code 0 \| consume_stdin_and_returns_with_given_code 0 \| consume_stdin_and_returns_with_given_code 42

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = 'Will return status 42.' ]
}

@test "run bats_pipe for 1st error status and fail on all of three" {
  run bats_pipe -1 returns_with_given_code 42 \| consume_stdin_and_returns_with_given_code 84 \| consume_stdin_and_returns_with_given_code 4

  [ "$status" -eq 84 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = 'Will return status 4.' ]
}

@test "run bats_pipe for 2nd error status and fail on first of three" {
  run bats_pipe -2 returns_with_given_code 42 \| describe_input \| describe_input

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 5 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tGot 0 args.' ]
  [ "${lines[3]}" = $'\tstdin:' ]
  [ "${lines[4]}" = $'\t\tWill return status 42.' ]
}

@test "run bats_pipe for 2nd error status and fail on first of three with arg separator" {
  run bats_pipe -2 -- returns_with_given_code 42 \| describe_input \| describe_input

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 5 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tGot 0 args.' ]
  [ "${lines[3]}" = $'\tstdin:' ]
  [ "${lines[4]}" = $'\t\tWill return status 42.' ]
}

@test "run bats_pipe for 2nd error status and fail on second of three" {
  run bats_pipe -2 returns_with_given_code 0 \| consume_stdin_and_returns_with_given_code 42 \| describe_input

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = 'Got 0 args.' ]
  [ "${lines[1]}" = 'stdin:' ]
  [ "${lines[2]}" = $'\tWill return status 42.' ]
}

@test "run bats_pipe for 2nd error status and fail on third of three" {
  run bats_pipe -2 returns_with_given_code 0 \| consume_stdin_and_returns_with_given_code 0 \| consume_stdin_and_returns_with_given_code 42

  [ "$status" -eq 42 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = 'Will return status 42.' ]
}

@test "run bats_pipe for 2nd error status and fail on all of three" {
  run bats_pipe -2 returns_with_given_code 42 \| consume_stdin_and_returns_with_given_code 84 \| consume_stdin_and_returns_with_given_code 4

  [ "$status" -eq 4 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = 'Will return status 4.' ]
}

@test "run bats_pipe for Nth error status too large" {
  run bats_pipe -8 returns_with_given_code 42 \| consume_stdin_and_returns_with_given_code 84

  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${lines[0]}" = "Usage error: Too large of -N argument given. Argument value: '8'." ]
}

@test "run bats_pipe with stdout as binary data" {
  run bats_pipe output_binary_data_and_returns_with_given_code 0 \| hexdump -v -e "1/1 \"0x%02X \""

  [ "$status" -eq 0 ]
  [ "$output" = "0x00 0xDE 0xAD 0xF0 0x0D " ]
}

@test "run bats_pipe with stdout as binary data with non-zero status" {
  run bats_pipe output_binary_data_and_returns_with_given_code 42 \| hexdump -v -e "1/1 \"0x%02X \""

  [ "$status" -eq 42 ]
  [ "$output" = "0x00 0xDE 0xAD 0xF0 0x0D " ]
}
