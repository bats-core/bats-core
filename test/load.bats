#!/usr/bin/env bats

setup() {
  load test_helper
  fixtures load
}

@test "find_library_load_path finds single-file libraries with the suffix .bash" {
  lib_dir="$BATS_TEST_TMPDIR/find_library_path/single_file_suffix"
  mkdir -p "$lib_dir"
  cp "${FIXTURE_ROOT}/test_helper.bash" "${lib_dir}/test_helper.bash"

  run find_library_load_path "$lib_dir/test_helper"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "$lib_dir/test_helper.bash" ]
}

@test "find_library_load_path finds single-file libraries without a suffix" {
  lib_dir="$BATS_TEST_TMPDIR/find_library_path/single_file_no_suffix"
  mkdir -p "$lib_dir"
  cp "${FIXTURE_ROOT}/test_helper.bash" "${lib_dir}/test_helper"

  run find_library_load_path "$lib_dir/test_helper"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "$lib_dir/test_helper" ]
}

@test "find_library_load_path finds directory libraries with a load.bash loader" {
  lib_dir="$BATS_TEST_TMPDIR/find_library_path/directory_loader_suffix"
  mkdir -p "$lib_dir/test_helper"
  cp "${FIXTURE_ROOT}/test_helper.bash" "${lib_dir}/test_helper/load.bash"

  run find_library_load_path "$lib_dir/test_helper"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "$lib_dir/test_helper/load.bash" ]
}

@test "find_library_load_path finds directory libraries with a load loader" {
  lib_dir="$BATS_TEST_TMPDIR/find_library_path/directory_loader_no_suffix"
  mkdir -p "$lib_dir/test_helper"
  cp "${FIXTURE_ROOT}/test_helper.bash" "${lib_dir}/test_helper/load"

  run find_library_load_path "$lib_dir/test_helper"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "$lib_dir/test_helper/load" ]
}

@test "find_library_load_path finds directory libraries without a loader" {
  lib_dir="$BATS_TEST_TMPDIR/find_library_path/directory_no_loader"
  mkdir -p "$lib_dir/test_helper"
  cp "${FIXTURE_ROOT}/test_helper.bash" "${lib_dir}/test_helper/not_a_loader.bash"

  run find_library_load_path "$lib_dir/test_helper"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "$lib_dir/test_helper" ]
}

@test "find_library_load_path returns 1 if no library load path is found" {
  lib_dir="$BATS_TEST_TMPDIR/find_library_path/return1"
  mkdir -p "$lib_dir/test_helper"
  cp "${FIXTURE_ROOT}/test_helper.bash" "${lib_dir}/test_helper/not_a_loader.bash"

  run find_library_load_path "$lib_dir/does_not_exist"
  [ $status -eq 1 ]
  [ -z "${lines[0]}" ]
}

@test "find_in_bats_lib_path recognizes files relative to test file" {
  test_dir="$BATS_TEST_TMPDIR/find_in_bats_lib_path/bats_test_dirname_priorty"
  mkdir -p "$test_dir"
  cp "$FIXTURE_ROOT/test_helper.bash" "$test_dir/"
  cp "$FIXTURE_ROOT/find_library_helper.bats" "$test_dir"

  BATS_LIB_PATH="" LIBRARY_NAME="test_helper" LIBRARY_PATH="$test_dir/test_helper.bash" run bats "$test_dir/find_library_helper.bats"
}

@test "find_in_bats_lib_path recognizes files in BATS_LIB_PATH" {
  test_dir="$BATS_TEST_TMPDIR/find_in_bats_lib_path/bats_test_dirname_priorty"
  mkdir -p "$test_dir"
  cp "$FIXTURE_ROOT/test_helper.bash" "$test_dir/"

  BATS_LIB_PATH="$test_dir" LIBRARY_NAME="test_helper" LIBRARY_PATH="$test_dir/test_helper.bash" run bats "$FIXTURE_ROOT/find_library_helper.bats"
}

@test "find_in_bats_lib_path returns 1 if no load path is found" {
  test_dir="$BATS_TEST_TMPDIR/find_in_bats_lib_path/no_load_path_found"
  mkdir -p "$test_dir"
  cp "$FIXTURE_ROOT/test_helper.bash" "$test_dir/"

  BATS_LIB_PATH="$test_dir" LIBRARY_NAME="test_helper" run bats "$FIXTURE_ROOT/find_library_helper_err.bats"
}

@test "find_in_bats_lib_path follows the priority of BATS_LIB_PATH" {
  test_dir="$BATS_TEST_TMPDIR/find_in_bats_lib_path/follows_priority"

  first_dir="$test_dir/first"
  mkdir -p "$first_dir"
  cp "$FIXTURE_ROOT/test_helper.bash" "$first_dir/target.bash"

  second_dir="$test_dir/second"
  mkdir -p "$second_dir"
  cp "$FIXTURE_ROOT/exit1.bash" "$second_dir/target.bash"

  BATS_LIB_PATH="$first_dir:$second_dir" LIBRARY_NAME="target" LIBRARY_PATH="$first_dir/target.bash" run bats "$FIXTURE_ROOT/find_library_helper.bats"
}

@test "load sources scripts relative to the current test file" {
  run bats "$FIXTURE_ROOT/load.bats"
  [ $status -eq 0 ]
}

@test "load sources relative scripts with filename extension" {
  HELPER_NAME="test_helper.bash" run bats "$FIXTURE_ROOT/load.bats"
  [ $status -eq 0 ]
}

@test "load aborts if the specified script does not exist" {
  HELPER_NAME="nonexistent" run bats "$FIXTURE_ROOT/load.bats"
  [ $status -eq 1 ]
}

@test "load sources scripts by absolute path" {
  HELPER_NAME="${FIXTURE_ROOT}/test_helper.bash" run bats "$FIXTURE_ROOT/load.bats"
  [ $status -eq 0 ]
}

@test "load aborts if the script, specified by an absolute path, does not exist" {
  HELPER_NAME="${FIXTURE_ROOT}/nonexistent" run bats "$FIXTURE_ROOT/load.bats"
  [ $status -eq 1 ]
}

@test "load relative script with ambiguous name" {
  HELPER_NAME="ambiguous" run bats "$FIXTURE_ROOT/load.bats"
  [ $status -eq 0 ]
}

@test "load loads scripts on the BATS_LIB_PATH" {
  path_dir="$BATS_TEST_TMPDIR/path"
  mkdir -p "$path_dir"
  cp "${FIXTURE_ROOT}/test_helper.bash" "${path_dir}/on_path"
  BATS_LIB_PATH="${path_dir}"  HELPER_NAME="on_path" run bats "$FIXTURE_ROOT/load.bats"
  [ $status -eq 0 ]
}

@test "load supports plain symbols" {
  local -r helper="${BATS_TEST_TMPDIR}/load_helper_plain"
  {
    echo "plain_variable='value of plain variable'"
    echo "plain_array=(test me hard)"
  } > "${helper}"

  load "${helper}"
  # shellcheck disable=SC2154
  [ "${plain_variable}" = 'value of plain variable' ]
  # shellcheck disable=SC2154
  [ "${plain_array[2]}" = 'hard' ]

  rm "${helper}"
}

@test "load doesn't support _declare_d symbols" {
  local -r helper="${BATS_TEST_TMPDIR}/load_helper_declared"
  {
    echo "declare declared_variable='value of declared variable'"
    echo "declare -r a_constant='constant value'"
    echo "declare -i an_integer=0x7e4"
    echo "declare -a an_array=(test me hard)"
    echo "declare -x exported_variable='value of exported variable'"
  } > "${helper}"

  load "${helper}"

  [ "${declared_variable:-}" != 'value of declared variable' ]
  [ "${a_constant:-}" != 'constant value' ]
  (( "${an_integer:-2019}" != 2020 ))
  [ "${an_array[2]:-}" != 'hard' ]
  [ "${exported_variable:-}" != 'value of exported variable' ]

  rm "${helper}"
}

@test "load supports libraries with loaders on the BATS_LIB_PATH" {
  path_dir="$BATS_TEST_TMPDIR/libraries/test_helper"
  mkdir -p "$path_dir"
  cp "${FIXTURE_ROOT}/test_helper.bash" "${path_dir}/load.bash"
  cp "${FIXTURE_ROOT}/exit1.bash" "${path_dir}/exit1.bash"
  BATS_LIB_PATH="${BATS_TEST_TMPDIR}/libraries" HELPER_NAME="test_helper" run bats "$FIXTURE_ROOT/load.bats"
}

@test "load supports libraries with loaders on the BATS_LIB_PATH with multiple libraries" {
  path_dir="$BATS_TEST_TMPDIR/libraries2/"
  for lib in liba libb libc; do
      mkdir -p "$path_dir/$lib"
      cp "${FIXTURE_ROOT}/exit1.bash" "$path_dir/$lib/load.bash"
  done
  mkdir -p "$path_dir/test_helper"
  cp "${FIXTURE_ROOT}/test_helper.bash" "$path_dir/test_helper/load.bash"
  BATS_LIB_PATH="$path_dir" HELPER_NAME="test_helper" run bats "$FIXTURE_ROOT/load.bats"
}

@test "load supports libraries without loaders on the BATS_LIB_PATH" {
  path_dir="$BATS_TEST_TMPDIR/libraries/test_helper"
  mkdir -p "$path_dir"
  cp "${FIXTURE_ROOT}/test_helper.bash" "${path_dir}/test_helper.bash"
  BATS_LIB_PATH="${BATS_TEST_TMPDIR}/libraries" HELPER_NAME="test_helper" run bats "$FIXTURE_ROOT/load.bats"
}

@test "load can handle whitespaces in BATS_LIB_PATH" {
  path_dir="$BATS_TEST_TMPDIR/libraries with spaces/"
  for lib in liba libb libc; do
      mkdir -p "$path_dir/$lib"
      cp "${FIXTURE_ROOT}/exit1.bash" "$path_dir/$lib/load.bash"
  done
  mkdir -p "$path_dir/test_helper"
  cp "${FIXTURE_ROOT}/test_helper.bash" "$path_dir/test_helper/load.bash"
  BATS_LIB_PATH="$path_dir" HELPER_NAME="test_helper" run bats "$FIXTURE_ROOT/load.bats"
}

@test "bats errors when a library errors while sourcing" {
  path_dir="$BATS_TEST_TMPDIR/libraries_err_sourcing/"
  mkdir -p "$path_dir/return1"
  cp "${FIXTURE_ROOT}/return1.bash" "$path_dir/return1/load.bash"

  BATS_LIB_PATH="$path_dir" run bats "$FIXTURE_ROOT/failing_load.bats"
  [ $status -eq 1 ]
}

@test "bats skips directories when sourcing .bash files in library" {
  path_dir="$BATS_TEST_TMPDIR/libraries_skip_dir/"
  mkdir -p "$path_dir/target_lib/adir.bash"
  cp "${FIXTURE_ROOT}/test_helper.bash" "$path_dir/target_lib/test_helper.bash"
  BATS_LIB_PATH="$path_dir" HELPER_NAME="target_lib" run bats "$FIXTURE_ROOT/load.bats"
}