# Bazel rules for running bats tests.

load("@bazel_skylib//lib:shell.bzl", "shell")

EXEC_TEST_TEMPLATE = """
#!/usr/bin/env bash
set -e
export TERM=dumb  # because of tputs
"{command}" {args} {srcs}
"""

def _exec_test_impl(ctx):
    # Generic test that runs an executable.  Right now, this is only
    # used for bats_test, but this might be used in the future for
    # shellcheck_test and others.
    runfiles = ctx.runfiles(
        files = ctx.files.srcs + ctx.files.deps,
        collect_data = True,
    )
    runfiles = runfiles.merge(ctx.attr._command.default_runfiles)
    srcs = [f.short_path for f in ctx.files.srcs]
    script = EXEC_TEST_TEMPLATE.format(
        command = ctx.executable._command.short_path,
        args = " ".join([shell.quote(x) for x in ctx.attr.extra_args]),
        srcs = " ".join([shell.quote(x) for x in srcs]),
    )
    ctx.actions.write(
        output = ctx.outputs.executable,
        is_executable = True,
        content = script,
    )
    return DefaultInfo(
        runfiles = runfiles,
    )

bats_test = rule(
    doc = """
      Runs a bats (Bash Automated Test System) test.
    """,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".bats"],
            doc = "\"bats\" tests to run.",
        ),
        "extra_args": attr.string_list(
            doc = "Extra arguments to pass to the command.",
        ),
        "deps": attr.label_list(
            doc = "Extra dependencies (other bats libraries?) to make available when test runs.",
            allow_files = True,
        ),
        "_command": attr.label(
            default = Label("@bats_core//:bats"),
            executable = True,
            cfg = "host",
        ),
    },
    test = True,
    implementation = _exec_test_impl,
)
