# Usage

Bats comes with two manual pages. After installation you can view them with `man
1 bats` (usage manual) and `man 7 bats` (writing test files manual). Also, you
can view the available command line options that Bats supports by calling Bats
with the `-h` or `--help` options. These are the options that Bats currently
supports:

```eval_rst
.. program-output:: ../../bin/bats --help
```

To run your tests, invoke the `bats` interpreter with one or more paths to test
files ending with the `.bats` extension, or paths to directories containing test
files. (`bats` will only execute `.bats` files at the top level of each
directory; it will not recurse unless you specify the `-r` flag.)

Test cases from each file are run sequentially and in isolation. If all the test
cases pass, `bats` exits with a `0` status code. If there are any failures,
`bats` exits with a `1` status code.

When you run Bats from a terminal, you'll see output as each test is performed,
with a check-mark next to the test's name if it passes or an "X" if it fails.

```text
$ bats addition.bats
 ✓ addition using bc
 ✓ addition using dc

2 tests, 0 failures
```

If Bats is not connected to a terminal—in other words, if you run it from a
continuous integration system, or redirect its output to a file—the results are
displayed in human-readable, machine-parsable [TAP format][tap-format].

You can force TAP output from a terminal by invoking Bats with the `--formatter tap`
option.

```text
$ bats --formatter tap addition.bats
1..2
ok 1 addition using bc
ok 2 addition using dc
```

With `--formatter junit`, it is possible
to output junit-compatible report files.

```text
$ bats --formatter junit addition.bats
1..2
ok 1 addition using bc
ok 2 addition using dc
```

If you have your own formatter, you can use an absolute path to the executable
to use it:

```bash
$ bats --formatter /absolute/path/to/my-formatter addition.bats
addition using bc WORKED
addition using dc FAILED
```

You can also generate test report files via `--report-formatter` which accepts
the same options as `--formatter`. By default, the file is stored in the current
workdir. However, it may be placed elsewhere by specifying the `--output` flag.

```text
$ bats --report-formatter junit addition.bats --output /tmp
1..2
ok 1 addition using bc
ok 2 addition using dc

$ cat /tmp/report.xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuites time="0.073">
<testsuite name="addition.bats" tests="2" failures="0" errors="0" skipped="0">
    <testcase classname="addition.bats" name="addition using bc" time="0.034" />
    <testcase classname="addition.bats" name="addition using dc" time="0.039" />
</testsuite>
</testsuites>
```

## Parallel Execution

```eval_rst
.. versionadded:: 1.0.0
```

By default, Bats will execute your tests serially. However, Bats supports
parallel execution of tests (provided you have [GNU parallel][gnu-parallel] or
a compatible replacement installed) using the `--jobs` parameter. This can
result in your tests completing faster (depending on your tests and the testing
hardware).

Ordering of parallelised tests is not guaranteed, so this mode may break suites
with dependencies between tests (or tests that write to shared locations). When
enabling `--jobs` for the first time be sure to re-run bats multiple times to
identify any inter-test dependencies or non-deterministic test behaviour.

When parallelizing, the results of a file only become visible after it has been finished.
You can use `--no-parallelize-across-files` to get immediate output at the cost of reduced
overall parallelity, as parallelization will only happen within files and files will be run
sequentially.

If you have files where tests within the file would interfere with each other, you can use
`--no-parallelize-within-files` to disable parallelization within all files.
If you want more fine-grained control, you can `export BATS_NO_PARALLELIZE_WITHIN_FILE=true` in `setup_file()`
or outside any function to disable parallelization only within the containing file.

## Test Coverage

Test coverage can be gathered when using [run][run-test-other-commands] to run
the code being tested as an external binary; it is not possible to gather test
coverage for shell functions because shell functions cannot be run by an
external program, and attempting to do so will likely cause the tests to fail.

Bats does not create or cleanup the test coverage directory, allowing
accumulation of coverage data over multiple runs.

Only [kcov][kcov] is currently supported:

- To enable test coverage globally use `--kcoverage_dir <directory>`.
- Test coverage can be selectively enabled by setting or clearing the
  environment variable `KCOVERAGE_DIR` before calling `run`.

Other programs for gathering test coverage can be supported by redefining the
`gather_coverage` function, e.g.:

```shell
gather_coverage() {
  my-coverage-program --flag1 --flag2 "$@"
}
```

If you would like to contribute support for other test coverage systems please
search for `gather_coverage`, `kcoverage_dir`, and `KCOVERAGE_DIR` to find the
code that will need to be extended.

[tap-format]: https://testanything.org
[gnu-parallel]: https://www.gnu.org/software/parallel/
[run-test-other-commands]: writing-tests.html#run-test-other-commands
[kcov]: https://github.com/SimonKagstrom/kcov
