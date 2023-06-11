#!/usr/bin/env bats

# bats file_tags=second:file

@test "Second One" { true; }
@test "Second Two" { true; }
@test "Second Three failed" { false; }
# bats test_tags=second:test
@test "Second Four test_tag" { true; }
# bats test_tags=second:test
@test "Second Five test_tag failed" { false; }
