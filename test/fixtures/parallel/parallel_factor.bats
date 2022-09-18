setup() {
  load '../../concurrent-coordination'
  echo setup "$BATS_TEST_NUMBER" >>"${MARKER_FILE?}"
}

teardown() {
  echo teardown "$BATS_TEST_NUMBER" >>"${MARKER_FILE?}"
}

@test "slow test 1" {
  single-use-barrier "parallel_factor" "$PARALLELITY"
}

@test "slow test 2" {
  single-use-barrier "parallel_factor" "$PARALLELITY"
}

@test "slow test 3" {
  single-use-barrier "parallel_factor" "$PARALLELITY"
}

@test "slow test 4" {
  single-use-barrier "parallel_factor" "$PARALLELITY"
}

@test "slow test 5" {
  single-use-barrier "parallel_factor" "$PARALLELITY"
}

@test "slow test 6" {
  single-use-barrier "parallel_factor" "$PARALLELITY"
}

@test "slow test 7" {
  single-use-barrier "parallel_factor" "$PARALLELITY"
}

@test "slow test 8" {
  single-use-barrier "parallel_factor" "$PARALLELITY"
}

@test "slow test 9" {
  single-use-barrier "parallel_factor" "$PARALLELITY"
}

@test "slow test 10" {
  single-use-barrier "parallel_factor" "$PARALLELITY"
}
