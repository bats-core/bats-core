export BATS_LIB_PATH=$BATS_TEST_DIRNAME
bats_load_library test_helper.bash

@test "calling a loaded helper" {
  help_me
}
