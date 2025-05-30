# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Provides helper that replaces @VARIABLE_NAME@ occurrences with values, as
specified by a provided map."""

_UNIX_TEMPLATE = """\
#!/usr/bin/env bash
# Generated by `@ncurses//bazel:automake_substitutions.bzl`
set -euo pipefail
cat {} \\
{}
> {}
"""

def _automake_substitution_impl(ctx):
    sed = ctx.executable._sed
    substitutions = ctx.attr.substitutions
    substitution_pipe = "\n".join([
        "| %s 's/@%s@/%s/g' \\" % (sed.path, variable_name, value)
        for variable_name, value in substitutions.items()
    ])

    if not substitution_pipe:
        substitution_pipe = "\\"

    output = ctx.outputs.out

    executable = ctx.actions.declare_file("{}.sh".format(ctx.label.name))
    ctx.actions.write(
        output = executable,
        content = _UNIX_TEMPLATE.format(
            ctx.file.src.path,
            substitution_pipe,
            output.path,
        ),
        is_executable = True,
    )

    ctx.actions.run(
        mnemonic = "NCursesAutomakeSubstitution",
        inputs = [ctx.file.src],
        outputs = [output],
        executable = executable,
        tools = [sed],
        use_default_shell_env = True,
    )

    return [DefaultInfo(
        files = depset([output]),
    )]

automake_substitution = rule(
    doc = """\
Replaces @VARIABLE_NAME@ occurrences with values.

Note: The current implementation does not allow slashes in variable
values.
""",
    implementation = _automake_substitution_impl,
    attrs = {
        "out": attr.output(
            doc = "The output file.",
            mandatory = True,
        ),
        "src": attr.label(
            doc = "The source file to modify",
            allow_single_file = True,
            mandatory = True,
        ),
        "substitutions": attr.string_dict(
            doc = "Substitutions to apply.",
            default = {},
        ),
        "_sed": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("@sed"),
        ),
    },
)
