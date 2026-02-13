# Test function that fails fast with errexit
failing_function() {
  echo "Step 1"
  false
  echo "Step 2: should not appear with errexit"
}

# Test function that succeeds
passing_function() {
  echo "Step 1"
  true
  echo "Step 2: should always appear"
}

@test "failing function without --errexit continues" {
  run failing_function
  [[ "$output" =~ "Step 1" ]] || false
  [[ "$output" =~ "Step 2: should not appear with errexit" ]] || false
  [ "$status" -eq 0 ]
}

@test "passing function works" {
  run passing_function
  [[ "$output" =~ "Step 1" ]] || false
  [[ "$output" =~ "Step 2: should always appear" ]] || false
  [ "$status" -eq 0 ]
}
