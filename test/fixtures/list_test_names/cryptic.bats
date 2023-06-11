#!/usr/bin/env bats

@test "nothing_special at-this-one" { true; }
@test "don't fail on 'single' or "Double" quotes" { true; }
@test "handles braces < [ } ({[]}) )(" { true; }
@test "handles `backticks`" { true; }
@test "handles \backslash incl sequences \n \r \t" { true; }
