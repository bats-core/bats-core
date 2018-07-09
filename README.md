# Bats-core: Bash Automated Testing System (2018)

[![Latest release](https://img.shields.io/github/release/bats-core/bats-core.svg)](https://github.com/bats-core/bats-core/releases/latest)
[![npm package](https://img.shields.io/npm/v/bats.svg)](https://www.npmjs.com/package/bats)
[![License](https://img.shields.io/github/license/bats-core/bats-core.svg)](https://github.com/bats-core/bats-core/blob/master/LICENSE.md)
[![Continuous integration status for Linux and macOS](https://img.shields.io/travis/bats-core/bats-core/master.svg?label=travis%20build)](https://travis-ci.org/bats-core/bats-core)
[![Continuous integration status for Windows](https://img.shields.io/appveyor/ci/bats-core/bats-core/master.svg?label=appveyor%20build)](https://ci.appveyor.com/project/bats-core/bats-core)

[![Join the chat in bats-core/bats-core on gitter](https://badges.gitter.im/bats-core/bats-core.svg)][gitter]

Bats is a [TAP][]-compliant testing framework for Bash.  It provides a simple
way to verify that the UNIX programs you write behave as expected.

[TAP]: https://testanything.org

A Bats test file is a Bash script with special syntax for defining test cases.
Under the hood, each test case is just a function with a description.

```bash
#!/usr/bin/env bats

@test "addition using bc" {
  result="$(echo 2+2 | bc)"
  [ "$result" -eq 4 ]
}

@test "addition using dc" {
  result="$(echo 2 2+p | dc)"
  [ "$result" -eq 4 ]
}
```

Bats is most useful when testing software written in Bash, but you can use it to
test any UNIX program.

Test cases consist of standard shell commands. Bats makes use of Bash's
`errexit` (`set -e`) option when running test cases. If every command in the
test case exits with a `0` status code (success), the test passes. In this way,
each line is an assertion of truth.

**Tuesday, September 19, 2017:** This is a mirrored fork of [Bats][bats-orig] at
commit [0360811][].  It was created via `git clone --bare` and `git push
--mirror`. See the [Background](#background) section below for more information.

[bats-orig]: https://github.com/sstephenson/bats
[0360811]: https://github.com/sstephenson/bats/commit/03608115df2071fff4eaaff1605768c275e5f81f

## Table of contents

- [Installation](#installation)
  - [Supported Bash versions](#supported-bash-versions)
  - [Homebrew](#homebrew)
  - [npm](#npm)
  - [Installing Bats from source](#installing-bats-from-source)
  - [Running Bats in Docker](#running-bats-in-docker)
    - [Building a Docker image](#building-a-docker-image)
- [Usage](#usage)
- [Writing tests](#writing-tests)
  - [`run`: Test other commands](#run-test-other-commands)
  - [`load`: Share common code](#load-share-common-code)
  - [`skip`: Easily skip tests](#skip-easily-skip-tests)
  - [`setup` and `teardown`: Pre- and post-test hooks](#setup-and-teardown-pre--and-post-test-hooks)
  - [Code outside of test cases](#code-outside-of-test-cases)
  - [File descriptor 3 (read this if Bats hangs)](#file-descriptor-3-read-this-if-bats-hangs)
  - [Printing to the terminal](#printing-to-the-terminal)
  - [Special variables](#special-variables)
- [Support](#support)
- [Version history](#version-history)
- [Background](#background)
  - [Why was this fork created?](#why-was-this-fork-created)
  - [What's the plan and why?](#whats-the-plan-and-why)
  - [Contact us](#contact-us)
- [Copyright](#copyright)

## Installation

### Supported Bash versions

The following is a list of Bash versions that are currently supported by Bats.
This list is composed of platforms that Bats has been tested on and is known to
work on without issues.

- Bash versions:
  - Everything from `3.2.57(1)` and higher (macOS's highest version)

- Operating systems:
  - Arch Linux
  - Alpine Linux
  - Ubuntu Linux
  - FreeBSD `10.x` and `11.x`
  - macOS
  - Windows 10

- Latest version for the following Windows platforms:
  - Git for Windows Bash (MSYS2 based)
  - Windows Subsystem for Linux
  - MSYS2
  - Cygwin

### Homebrew

On macOS, you can install [Homebrew](https://brew.sh/) if you haven't already,
then run:

```bash
$ brew install bats-core
```

### npm

You can install the [Bats npm package](https://www.npmjs.com/package/bats) via:

```
# To install globally:
$ npm install -g bats

# To install into your project and save it as one of the "devDependencies" in
# your package.json:
$ npm install --save-dev bats
```

### Installing Bats from source

Check out a copy of the Bats repository. Then, either add the Bats `bin`
directory to your `$PATH`, or run the provided `install.sh` command with the
location to the prefix in which you want to install Bats. For example, to
install Bats into `/usr/local`,

    $ git clone https://github.com/bats-core/bats-core.git
    $ cd bats-core
    $ ./install.sh /usr/local

Note that you may need to run `install.sh` with `sudo` if you do not have
permission to write to the installation prefix.

### Running Bats in Docker

There is an official image on the Docker Hub:

    $ docker run -it bats/bats:latest --version

#### Building a Docker image

Check out a copy of the Bats repository, then build a container image:

    $ git clone https://github.com/bats-core/bats-core.git
    $ cd bats-core
    $ docker build --tag bats/bats:latest .

This creates a local Docker image called `bats/bats:latest` based on [Alpine
Linux](https://github.com/gliderlabs/docker-alpine/blob/master/docs/usage.md) 
(to push to private registries, tag it with another organisation, e.g. 
`my-org/bats:latest`).

To run Bats' internal test suite (which is in the container image at
`/opt/bats/test`):

    $ docker run -it bats/bats:latest /opt/bats/test

To run a test suite from your local machine, mount in a volume and direct Bats
to its path inside the container:

    $ docker run -it -v "$(pwd):/code" bats/bats:latest /code/test

This is a minimal Docker image. If more tools are required this can be used as a 
base image in a Dockerfile using `FROM <Docker image>`.  In the future there may 
be images based on Debian, and/or with more tools installed (`curl` and `openssl`,
for example). If you require a specific configuration please search and +1 an
issue or [raise a new issue](https://github.com/bats-core/bats-core/issues).

Further usage examples are in [the wiki](https://github.com/bats-core/bats-core/wiki/Docker-Usage-Examples).

## Usage

Bats comes with two manual pages. After installation you can view them with `man
1 bats` (usage manual) and `man 7 bats` (writing test files manual). Also, you
can view the available command line options that Bats supports by calling Bats
with the `-h` or `--help` options. These are the options that Bats currently
supports:

```
Bats x.y.z
Usage: bats [-c] [-r] [-p | -t] <test> [<test> ...]

  <test> is the path to a Bats test file, or the path to a directory
  containing Bats test files.

  -c, --count      Count the number of test cases without running any tests
  -h, --help       Display this help message
  -p, --pretty     Show results in pretty format (default for terminals)
  -r, --recursive  Include tests in subdirectories
  -t, --tap        Show results in TAP format
  -v, --version    Display the version number
```

To run your tests, invoke the `bats` interpreter with one or more paths to test
files ending with the `.bats` extension, or paths to directories containing test
files. (`bats` will not only discover `.bats` files at the top level of each
directory; it will not recurse.)

Test cases from each file are run sequentially and in isolation. If all the test
cases pass, `bats` exits with a `0` status code. If there are any failures,
`bats` exits with a `1` status code.

When you run Bats from a terminal, you'll see output as each test is performed,
with a check-mark next to the test's name if it passes or an "X" if it fails.

    $ bats addition.bats
     ✓ addition using bc
     ✓ addition using dc

    2 tests, 0 failures

If Bats is not connected to a terminal—in other words, if you run it from a
continuous integration system, or redirect its output to a file—the results are
displayed in human-readable, machine-parsable [TAP format][TAP].

You can force TAP output from a terminal by invoking Bats with the `--tap`
option.

    $ bats --tap addition.bats
    1..2
    ok 1 addition using bc
    ok 2 addition using dc

## Writing tests

Each Bats test file is evaluated _n+1_ times, where _n_ is the number of
test cases in the file. The first run counts the number of test cases,
then iterates over the test cases and executes each one in its own
process.

For more details about how Bats evaluates test files, see [Bats Evaluation
Process][bats-eval] on the wiki.

[bats-eval]: https://github.com/bats-core/bats-core/wiki/Bats-Evaluation-Process

### `run`: Test other commands

Many Bats tests need to run a command and then make assertions about its exit
status and output. Bats includes a `run` helper that invokes its arguments as a
command, saves the exit status and output into special global variables, and
then returns with a `0` status code so you can continue to make assertions in
your test case.

For example, let's say you're testing that the `foo` command, when passed a
nonexistent filename, exits with a `1` status code and prints an error message.

```bash
@test "invoking foo with a nonexistent file prints an error" {
  run foo nonexistent_filename
  [ "$status" -eq 1 ]
  [ "$output" = "foo: no such file 'nonexistent_filename'" ]
}
```

The `$status` variable contains the status code of the command, and the
`$output` variable contains the combined contents of the command's standard
output and standard error streams.

A third special variable, the `$lines` array, is available for easily accessing
individual lines of output. For example, if you want to test that invoking `foo`
without any arguments prints usage information on the first line:

```bash
@test "invoking foo without arguments prints usage" {
  run foo
  [ "$status" -eq 1 ]
  [ "${lines[0]}" = "usage: foo <filename>" ]
}
```

### `load`: Share common code

You may want to share common code across multiple test files. Bats includes a
convenient `load` command for sourcing a Bash source file relative to the
location of the current test file. For example, if you have a Bats test in
`test/foo.bats`, the command

```bash
load test_helper
```

will source the script `test/test_helper.bash` in your test file. This can be
useful for sharing functions to set up your environment or load fixtures.

### `skip`: Easily skip tests

Tests can be skipped by using the `skip` command at the point in a test you wish
to skip.

```bash
@test "A test I don't want to execute for now" {
  skip
  run foo
  [ "$status" -eq 0 ]
}
```

Optionally, you may include a reason for skipping:

```bash
@test "A test I don't want to execute for now" {
  skip "This command will return zero soon, but not now"
  run foo
  [ "$status" -eq 0 ]
}
```

Or you can skip conditionally:

```bash
@test "A test which should run" {
  if [ foo != bar ]; then
    skip "foo isn't bar"
  fi

  run foo
  [ "$status" -eq 0 ]
}
```

### `setup` and `teardown`: Pre- and post-test hooks

You can define special `setup` and `teardown` functions, which run before and
after each test case, respectively. Use these to load fixtures, set up your
environment, and clean up when you're done.

### Code outside of test cases

You can include code in your test file outside of `@test` functions.  For
example, this may be useful if you want to check for dependencies and fail
immediately if they're not present. However, any output that you print in code
outside of `@test`, `setup` or `teardown` functions must be redirected to
`stderr` (`>&2`). Otherwise, the output may cause Bats to fail by polluting the
TAP stream on `stdout`.

### File descriptor 3 (read this if Bats hangs)

Bats makes a separation between output from the code under test and output that
forms the TAP stream (which is produced by Bats internals). This is done in
order to produce TAP-compliant output. In the [Printing to the
terminal](#printing-to-the-terminal) section, there are details on how to use
file descriptor 3 to print custom text properly.

A side effect of using file descriptor 3 is that, under some circumstances, it
can cause Bats to block and execution to seem dead without reason. This can
happen if a child process is spawned in the background from a test. In this
case, the child process will inherit file descriptor 3. Bats, as the parent
process, will wait for the file descriptor to be closed by the child process
before continuing execution. If the child process takes a lot of time to
complete (eg if the child process is a `sleep 100` command or a background
service that will run indefinitely), Bats will be similarly blocked for the same
amount of time.

**To prevent this from happening, close FD 3 explicitly when running any command
that may launch long-running child processes**, e.g. `command_name 3>- &`.

### Printing to the terminal

Bats produces output compliant with [version 12 of the TAP protocol][TAP]. The
produced TAP stream is by default piped to a pretty formatter for human
consumption, but if Bats is called with the `-t` flag, then the TAP stream is
directly printed to the console.

This has implications if you try to print custom text to the terminal. As
mentioned in [File descriptor 3](#file-descriptor-3), bats provides a special
file descriptor, `&3`, that you should use to print your custom text. Here are
some detailed guidelines to refer to:

- Printing **from within a test function**:
  - To have text printed from within a test function you need to redirect the
    output to file descriptor 3, eg `echo 'text' >&3`. This output will become
    part of the TAP stream. You are encouraged to prepend text printed this way
    with a hash (eg `echo '# text' >&3`) in order to produce 100% TAP compliant
    output. Otherwise, depending on the 3rd-party tools you use to analyze the
    TAP stream, you can encounter unexpected behavior or errors.

  - The pretty formatter that Bats uses by default to process the TAP stream
    will filter out and not print text output to file descriptor 3.

  - Text that is output directly to stdout or stderr (file descriptor 1 or 2),
    ie `echo 'text'` is considered part of the test function output and is
    printed only on test failures for diagnostic purposes, regardless of the
    formatter used (TAP or pretty).

- Printing **from within the `setup` or `teardown` functions**: The same hold
  true as for printing with test functions.

- Printing **outside test or `setup`/`teardown` functions**:
  - Regardless of where text is redirected to (stdout, stderr or file descriptor
    3) text is immediately visible in the terminal.

  - Text printed in such a way, will disable pretty formatting. Also, it will
    make output non-compliant with the TAP spec. The reason for this is that
    each test file is evaluated n+1 times (as metioned
    [earlier](#writing-tests)). The first run will cause such output to be
    produced before the [_plan line_][tap-plan] is printed, contrary to the spec
    that requires the _plan line_ to be either the first or the last line of the
    output.

  - Due to internal pipes/redirects, output to stderr is always printed first.

[tap-plan]: https://testanything.org/tap-specification.html#the-plan

### Special variables

There are several global variables you can use to introspect on Bats tests:

* `$BATS_TEST_FILENAME` is the fully expanded path to the Bats test file.
* `$BATS_TEST_DIRNAME` is the directory in which the Bats test file is located.
* `$BATS_TEST_NAMES` is an array of function names for each test case.
* `$BATS_TEST_NAME` is the name of the function containing the current test
  case.
* `$BATS_TEST_DESCRIPTION` is the description of the current test case.
* `$BATS_TEST_NUMBER` is the (1-based) index of the current test case in the
  test file.
* `$BATS_TMPDIR` is the location to a directory that may be used to store
  temporary files.

## Support

The Bats source code repository is [hosted on
GitHub](https://github.com/bats-core/bats-core). There you can file bugs on the
issue tracker or submit tested pull requests for review.

For real-world examples from open-source projects using Bats, see [Projects
Using Bats](https://github.com/bats-core/bats-core/wiki/Projects-Using-Bats) on
the wiki.

To learn how to set up your editor for Bats syntax highlighting, see [Syntax
Highlighting](https://github.com/bats-core/bats-core/wiki/Syntax-Highlighting)
on the wiki.

## Version history

Bats is [SemVer compliant](https://semver.org/).

*1.1.0* (July 8, 2018)

This is the first release with new features relative to the original Bats 0.4.0.

Added:
* The `-r, --recursive` flag to scan directory arguments recursively for
  `*.bats` files (#109)
* The `contrib/rpm/bats.spec` file to build RPMs (#111)

Changed:
* Travis exercises latest versions of Bash from 3.2 through 4.4 (#116, #117)
* Error output highlights invalid command line options (#45, #46, #118)
* Replaced `echo` with `printf` (#120)

Fixed:
* Fixed `BATS_ERROR_STATUS` getting lost when `bats_error_trap` fired multiple
  times under Bash 4.2.x (#110)
* Updated `bin/bats` symlink resolution, handling the case on CentOS where
  `/bin` is a symlink to `/usr/bin` (#113, #115)

*1.0.2* (June 18, 2018)

* Fixed sstephenson/bats#240, whereby `skip` messages containing parentheses
  were truncated (#48)
* Doc improvements:
  * Docker usage (#94)
  * Better README badges (#101)
  * Better installation instructions (#102, #104)
* Packaging/installation improvements:
  * package.json update (#100)
  * Moved `libexec/` files to `libexec/bats-core/`, improved `install.sh` (#105)

*1.0.1* (June 9, 2018)

* Fixed a `BATS_CWD` bug introduced in #91 whereby it was set to the parent of
  `PWD`, when it should've been set to `PWD` itself (#98). This caused file
  names in stack traces to contain the basename of `PWD` as a prefix, when the
  names should've been purely relative to `PWD`.
* Ensure the last line of test output prints when it doesn't end with a newline
  (#99). This was a quasi-bug introduced by replacing `sed` with `while` in #88.

*1.0.0* (June 8, 2018)

`1.0.0` generally preserves compatibility with `0.4.0`, but with some Bash
compatibility improvements and a massive performance boost. In other words:

- all existing tests should remain compatible
- tests that might've failed or exhibited unexpected behavior on earlier
  versions of Bash should now also pass or behave as expected

Changes:

* Added support for Docker.
* Added support for test scripts that have the [unofficial strict
  mode](http://redsymbol.net/articles/unofficial-bash-strict-mode/) enabled.
* Improved stability on Windows and macOS platforms.
* Massive performance improvements, especially on Windows (#8)
* Workarounds for inconsistent behavior between Bash versions (#82)
* Workaround for preserving stack info after calling an exported function under
  Bash < 4.4 (#87)
* Fixed TAP compliance for skipped tests
* Added support for tabs in test names.
* `bin/bats` and `install.sh` now work reliably on Windows (#91)

*0.4.0* (August 13, 2014)

* Improved the display of failing test cases. Bats now shows the source code of
  failing test lines, along with full stack traces including function names,
  filenames, and line numbers.
* Improved the display of the pretty-printed test summary line to include the
  number of skipped tests, if any.
* Improved the speed of the preprocessor, dramatically shortening test and suite
  startup times.
* Added support for absolute pathnames to the `load` helper.
* Added support for single-line `@test` definitions.
* Added bats(1) and bats(7) manual pages.
* Modified the `bats` command to default to TAP output when the `$CI` variable
  is set, to better support environments such as Travis CI.

*0.3.1* (October 28, 2013)

* Fixed an incompatibility with the pretty formatter in certain environments
  such as tmux.
* Fixed a bug where the pretty formatter would crash if the first line of a test
  file's output was invalid TAP.

*0.3.0* (October 21, 2013)

* Improved formatting for tests run from a terminal. Failing tests are now
  colored in red, and the total number of failing tests is displayed at the end
  of the test run. When Bats is not connected to a terminal (e.g. in CI runs),
  or when invoked with the `--tap` flag, output is displayed in standard TAP
  format.
* Added the ability to skip tests using the `skip` command.
* Added a message to failing test case output indicating the file and line
  number of the statement that caused the test to fail.
* Added "ad-hoc" test suite support. You can now invoke `bats` with multiple
  filename or directory arguments to run all the specified tests in aggregate.
* Added support for test files with Windows line endings.
* Fixed regular expression warnings from certain versions of Bash.
* Fixed a bug running tests containing lines that begin with `-e`.

*0.2.0* (November 16, 2012)

* Added test suite support. The `bats` command accepts a directory name
  containing multiple test files to be run in aggregate.
* Added the ability to count the number of test cases in a file or suite by
  passing the `-c` flag to `bats`.
* Preprocessed sources are cached between test case runs in the same file for
  better performance.

*0.1.0* (December 30, 2011)

* Initial public release.

---

## Background

### Why was this fork created?

The original Bats repository needed new maintainers, and has not been actively
maintained since 2013. While there were volunteers for maintainers, attempts to
organize issues, and outstanding PRs, the lack of write-access to the repo
hindered progress severely.

### What's the plan and why?

The rough plan, originally [outlined
here](https://github.com/sstephenson/bats/issues/150#issuecomment-323845404) is
to create a new, mirrored mainline (this repo!). An excerpt:

> **1. Roadmap 1.0:**
> There are already existing high-quality PRs, and often-requested features and
> issues, especially here at
> [#196](https://github.com/sstephenson/bats/issues/196). Leverage these and
> **consolidate into a single roadmap**.
>
> **2. Create or choose a fork or *mirror* of this repo to use as the new
> mainline:**
> Repoint existing PRs (whichever ones are possible) to the new mainline, get
> that repo to a stable 1.0. IMO we should create an organization and grant 2-3
> people admin and write access.

Doing it this way accomplishes a number of things:

1. Removes the dependency on the original maintainer
1. Enables collaboration and contribution flow again
1. Allows the possibility of merging back to original, or merging from original
   if or when the need arises
1. Prevents lock-out by giving administrative access to more than one person,
   increases transferability

### Contact us

- We are `#bats` on freenode

## Copyright

© 2018 bats-core organization

© 2014 Sam Stephenson

Bats is released under an MIT-style license; see `LICENSE.md` for details.

[gitter]: https://gitter.im/bats-core/bats-core?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge
