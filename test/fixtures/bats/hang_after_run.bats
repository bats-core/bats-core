setup() {
  load '../../concurrent-coordination'
}

@test "test" {
  run true
  single-use-latch::signal hang_after_run
  sleep 10
}
