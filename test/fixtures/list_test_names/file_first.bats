#!/usr/bin/env bats

@test "First One" { true; }
@test 'First Two' { true; }
@test "First Three failed" { false; }
# bats test_tags=first:test
@test "First Four test_tag" { true; }
# bats test_tags=first:test,tag:failed
@test "First Five test_tag failed" { false; }
