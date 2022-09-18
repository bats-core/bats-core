setup() {
  load '../../concurrent-coordination'
}

@test "test" {
  single-use-latch::signal hang_after_run
  run true
  sleep 10
}
