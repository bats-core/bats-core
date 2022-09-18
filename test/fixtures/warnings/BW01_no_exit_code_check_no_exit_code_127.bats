@test "Don't trigger BW01 with exit code !=127 and no check" {
  run exit 1
}
