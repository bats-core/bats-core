[![Latest release](https://img.shields.io/github/release/bats-core/bats-core.svg)](https://github.com/bats-core/bats-core/releases/latest)
[![npm package](https://img.shields.io/npm/v/bats.svg)](https://www.npmjs.com/package/bats)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/bats-core/bats-core/blob/master/LICENSE.md)
[![Continuous integration status](https://github.com/bats-core/bats-core/workflows/Tests/badge.svg)](https://github.com/bats-core/bats-core/actions?query=workflow%3ATests)
[![Read the docs status](https://readthedocs.org/projects/bats-core/badge/)](https://bats-core.readthedocs.io)

[![Join the chat in bats-core/bats-core on gitter](https://badges.gitter.im/bats-core/bats-core.svg)][gitter]

<div align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/source/assets/dark_mode_cube.svg">
  <img alt="" src="docs/source/assets/light_mode_cube.svg">
</picture>
</div>

# Bats-core: Bash Automated Testing System

Bats is a [TAP](https://testanything.org/)-compliant testing framework for Bash
3.2 or above.  It provides a simple way to verify that the UNIX programs you
write behave as expected.

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

## Table of contents

**NOTE** The documentation has moved to <https://bats-core.readthedocs.io>

<!-- toc -->

- [Testing](#testing)
- [Support](#support)
- [Contributing](#contributing)
- [Contact](#contact)
- [Version history](#version-history)
- [Background](#background)
  * [What's the plan and why?](#whats-the-plan-and-why)
  * [Why was this fork created?](#why-was-this-fork-created)
- [Copyright](#copyright)

<!-- tocstop -->

## Testing

```sh
bin/bats --tap test
```

See also the [CI](./.github/workflows/tests.yml) settings for the current test environment and
scripts.

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

## Contributing

For now see the [`docs`](docs) folder for project guides, work with us on the wiki
or look at the other communication channels.

## Contact

- You can find and chat with us on our [Gitter].

## Version history

See `docs/CHANGELOG.md`.

## Background

<!-- markdownlint-disable MD026 -->
### Why was this fork created?
<!-- markdownlint-enable MD026 -->

There was an initial [call for maintainers][call-maintain] for the original Bats repository, but write access to it could not be obtained. With development activity stalled, this fork allowed ongoing maintenance and forward progress for Bats.

**Tuesday, September 19, 2017:** This was forked from [Bats][bats-orig] at
commit [0360811][].  It was created via `git clone --bare` and `git push
--mirror`.

As of **Thursday, April 29, 2021:** the original [Bats][bats-orig] has been
archived by the owner and is now read-only.

This [bats-core](https://github.com/bats-core/bats-core) repo is now the community-maintained Bats project.

[call-maintain]: https://github.com/sstephenson/bats/issues/150
[bats-orig]: https://github.com/sstephenson/bats
[0360811]: https://github.com/sstephenson/bats/commit/03608115df2071fff4eaaff1605768c275e5f81f

## Copyright

The Bats Logo was created by [Vukory](https://www.artstation.com/vukory) ([Github](https://github.com/vukory)) and sponsored by [SethFalco](https://github.com/SethFalco). If you want to use our logo, have a look at our [guidelines](./docs/source/assets/README.md#Usage-Guide-for-Third-Parties).

© 2017-2024 bats-core organization

© 2011-2016 Sam Stephenson

Bats is released under an MIT-style license; see `LICENSE.md` for details.

See the [parent project](https://github.com/bats-core) at GitHub or the
[AUTHORS](AUTHORS) file for the current project maintainer team.

[gitter]: https://gitter.im/bats-core/bats-core
