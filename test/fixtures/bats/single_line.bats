@test "empty" { }

@test "passing" { true; }

@test "input redirection" { [ "$(</dev/stdin)" = hello ]; } <<EOS
hello
EOS

@test "failing" { false; }
