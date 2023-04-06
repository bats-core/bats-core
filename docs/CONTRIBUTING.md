# Contributing Guidelines

## Welcome!

Thank you for considering contributing to this project's 
development and/or documentation. Just a reminder: if you're new to this project
or to OSS and want to find issues to work on, please check the following labels 
on issues:

- [help wanted][helpwantedlabel]
- [docs][docslabel]
- [good first issue][goodfirstissuelabel]

[docslabel]:           https://github.com/bats-core/bats-core/labels/docs
[helpwantedlabel]:     https://github.com/bats-core/bats-core/labels/help%20wanted
[goodfirstissuelabel]: https://github.com/bats-core/bats-core/labels/good%20first%20issue

To see all labels and their meanings, [check this wiki page][labelswiki].

[labelswiki]: https://github.com/bats-core/bats-core/wiki/GitHub-Issue-Labels

## Table of contents

* [Contributing Guidelines](#contributing-guidelines)
  * [Welcome!](#welcome)
  * [Table of contents](#table-of-contents)
  * [Quick links](#quick-links)
  * [Code of conduct](#code-of-conduct)
  * [Asking questions](#asking-questions)
  * [Updating documentation](#updating-documentation)
  * [Testing](#testing)
  * [Coding conventions](#coding-conventions)
      * [Function declarations](#function-declarations)
      * [Variable and parameter declarations](#variable-and-parameter-declarations)
      * [Command substitution](#command-substitution)
      * [Process substitution](#process-substitution)
      * [Conditionals and loops](#conditionals-and-loops)
      * [Generating output](#generating-output)
      * [Signal names](#signal-names)
      * [Gotchas](#gotchas)
  * [Open Source License](#open-source-license)
  * [Credits](#credits)

## Quick links

- [Gitter channel →][gitterurl]: Feel free to come chat with us on Gitter
- [README →][README]
- [Code of conduct →][CODE_OF_CONDUCT]
- [License information →][LICENSE]
- [Original repository →][repohome]
- [Issues →][repoissues]
- [Pull requests →][repoprs]
- [Milestones →][repomilestones]
- [Projects →][repoprojects]

[README]: https://github.com/bats-core/bats-core/blob/master/README.md
[CODE_OF_CONDUCT]: https://github.com/bats-core/bats-core/blob/master/docs/CODE_OF_CONDUCT.md
[LICENSE]: https://github.com/bats-core/bats-core/blob/master/LICENSE.md

## Code of conduct

Harassment or rudeness of any kind will not be tolerated, period. For
specifics, see the [CODE_OF_CONDUCT][] file.

## Asking questions

Please check the [documentation][documentation] or existing [discussions][] and [issues][repoissues] first.

If you cannot find an answer to your question, please feel free to hop on our 
[Gitter][gitterurl]. [![Gitter](https://badges.gitter.im/bats-core/bats-core.svg)](https://gitter.im/bats-core/bats-core)

## Updating documentation

We love documentation and people who love documentation!

If you love writing clear, accessible docs, please don't be shy about pull 
requests. Remember: docs are just as important as code.

Also: _no typo is too small to fix!_ Really. Of course, batches of fixes are
preferred, but even one nit is one nit too many.

## Testing

- Continuous integration status: [![Tests](https://github.com/bats-core/bats-core/workflows/Tests/badge.svg)](https://github.com/bats-core/bats-core/actions?query=workflow%3ATests)

To run all tests:
```sh
bin/bats test
```

To run a single test file:
```sh
bin/bats test/file.bats
```

When running from a terminal, Bats uses the *pretty* formatter by default.
However, to debug Bats you might need to see the raw test output. 
The **cat** formatter is intended as an internal debugging tool because
it does not process test outputs.
To use it, run Bats with the `--formatter cat` option.

## Coding conventions

Use (`shfmt`)[https://github.com/mvdan/sh#shfmt] and [ShellCheck](https://www.shellcheck.net/). The CI will enforce this.

Use `snake_case` for all identifiers.

### Function declarations

- Declare functions without the `function` keyword.
- Strive to always use `return`, never `exit`, unless an error condition is
  severe enough to warrant it.
  - Calling `exit` makes it difficult for the caller to recover from an error,
    or to compose new commands from existing ones.

### Variable and parameter declarations

- Declare all variables inside functions using `local`.
- Declare temporary file-level variables using `declare`. Use `unset` to remove
  them when finished.
- Don't use `local -r`, as a readonly local variable in one scope can cause a
  conflict when it calls a function that declares a `local` variable of the same
  name.
- Don't use type flags with `declare` or `local`. Assignments to integer
  variables in particular may behave differently, and it has no effect on array
  variables.
- For most functions, the first lines should use `local` declarations to
  assign the original positional parameters to more meaningful names, e.g.:
  ```bash
  format_summary() {
    local cmd_name="$1"
    local summary="$2"
    local longest_name_len="$3"
  ```
  For very short functions, this _may not_ be necessary, e.g.:
  ```bash
  has_spaces() {
    [[ "$1" != "${1//[[:space:]]/}" ]]
  }
  ```

### Command substitution

- If possible, don't. While this capability is one of Bash's core strengths,
  every new process created by Bats makes the framework slower, and speed is
  critical to encouraging the practice of automated testing. (This is especially
  true on Windows, [where process creation is one or two orders of magnitude
  slower][win-slow]. See [bats-core/bats-core#8][pr-8] for an illustration of
  the difference avoiding subshells makes.) Bash is quite powerful; see if you
  can do what you need in pure Bash first.
- If you need to capture the output from a function, store the output using
  `printf -v` instead if possible. `-v` specifies the name of the variable into
  which to write the result; the caller can supply this name as a parameter.
- If you must use command substitution, use `$()` instead of backticks, as it's
  more robust, more searchable, and can be nested.

[win-slow]: https://rufflewind.com/2014-08-23/windows-bash-slow
[pr-8]: https://github.com/bats-core/bats-core/pull/8

### Process substitution

- If possible, don't use it. See the advice on avoiding subprocesses and using
  `printf -v` in the **Command substitution** section above.
- Use wherever necessary and possible, such as when piping input into a `while`
  loop (which avoids having the loop body execute in a subshell) or running a
  command taking multiple filename arguments based on output from a function or
  pipeline (e.g.  `diff`).
- *Warning*: It is impossible to directly determine the exit status of a process
  substitution; emitting an exit status as the last line of output is a possible
  workaround.

### Conditionals and loops

- Always use `[[` and `]]` for evaluating variables. Per the guideline under
  **Formatting**, quote variables and strings within the brackets, but not
  regular expressions (or variables containing regular expressions) appearing
  on the right side of the `=~` operator.

### Generating output

- Use `printf` instead of `echo`. Both are Bash builtins, and there's no
  perceptible performance difference when running Bats under the `time` builtin.
  However, `printf` provides a more consistent experience in general, as `echo`
  has limitations to the arguments it accepts, and even the same version of Bash
  may produce different results for `echo` based on how the binary was compiled.
  See [Stack Overflow: Why is printf better than echo?][printf-vs-echo] for
  excruciating details.

[printf-vs-echo]: https://unix.stackexchange.com/a/65819

### Signal names

Always use upper case signal names (e.g. `trap - INT EXIT`) to avoid locale 
dependent errors. In some locales (for example Turkish, see 
[Turkish dotless i](https://en.wikipedia.org/wiki/Dotted_and_dotless_I)) lower 
case signal names cause Bash to error. An example of the problem:

```bash
$ echo "tr_TR.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen tr_TR.UTF-8 # Ubuntu derivatives
$ LC_CTYPE=tr_TR.UTF-8 LC_MESSAGES=C bash -c 'trap - int && echo success'
bash: line 0: trap: int: invalid signal specification
$ LC_CTYPE=tr_TR.UTF-8 LC_MESSAGES=C bash -c 'trap - INT && echo success'
success
```


## Credits

The [official bash logo](https://github.com/odb/official-bash-logo) is copyrighted
by the [Free Software Foundation](https://www.fsf.org/), 2016 under the [Free Art License](http://artlibre.org/licence/lal/en/)

This guide borrows **heavily** from [@mbland's go-script-bash][gsb] (with some 
sections directly quoted), which in turn was
drafted with tips from [Wrangling Web Contributions: How to Build
a CONTRIBUTING.md][moz] and with some inspiration from [the Atom project's
CONTRIBUTING.md file][atom].

[gsb]:  https://github.com/mbland/go-script-bash/blob/master/CONTRIBUTING.md
[moz]:  https://mozillascience.github.io/working-open-workshop/contributing/
[atom]: https://github.com/atom/atom/blob/master/CONTRIBUTING.md

[discussions]:    https://github.com/bats-core/bats-core/discussions
[documentation]:  https://bats-core.readthedocs.io/
[repoprojects]:   https://github.com/bats-core/bats-core/projects
[repomilestones]: https://github.com/bats-core/bats-core/milestones
[repoprs]:        https://github.com/bats-core/bats-core/pulls
[repoissues]:     https://github.com/bats-core/bats-core/issues
[repohome]:       https://github.com/bats-core/bats-core

[osmit]:          https://opensource.org/licenses/MIT

[gitterurl]:      https://gitter.im/bats-core/bats-core
