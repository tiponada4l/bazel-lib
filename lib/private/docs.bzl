"Helpers for generating stardoc documentation"

load("@io_bazel_stardoc//stardoc:stardoc.bzl", "stardoc")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@bazel_skylib//rules:diff_test.bzl", "diff_test")

def stardoc_with_diff_test(
        bzl_library_target,
        out_label,
        aspect_template = "@io_bazel_stardoc//stardoc:templates/markdown_tables/aspect.vm",
        func_template = "@io_bazel_stardoc//stardoc:templates/markdown_tables/func.vm",
        header_template = "@io_bazel_stardoc//stardoc:templates/markdown_tables/header.vm",
        provider_template = "@io_bazel_stardoc//stardoc:templates/markdown_tables/provider.vm",
        rule_template = "@io_bazel_stardoc//stardoc:templates/markdown_tables/rule.vm"):
    """Creates a stardoc target coupled with a `diff_test` for a given `bzl_library`.

    This is helpful for minimizing boilerplate in repos wih lots of stardoc targets.

    Args:
        bzl_library_target: the label of the `bzl_library` target to generate documentation for
        out_label: the label of the output MD file
        aspect_template: the label or path to the Velocity aspect template to use with stardoc
        func_template: the label or path to the Velocity function/macro template to use with stardoc
        header_template: the label or path to the Velocity header template to use with stardoc
        provider_template: the label or path to the Velocity provider template to use with stardoc
        rule_template: the label or path to the Velocity rule template to use with stardoc
    """

    out_file = out_label.replace("//", "").replace(":", "/")

    # Generate MD from .bzl
    stardoc(
        name = out_file.replace("/", "_").replace(".md", "-docgen"),
        out = out_file.replace(".md", "-docgen.md"),
        input = bzl_library_target + ".bzl",
        deps = [bzl_library_target],
        aspect_template = aspect_template,
        func_template = func_template,
        header_template = header_template,
        provider_template = provider_template,
        rule_template = rule_template,
    )

    # Ensure that the generated MD has been updated in the local source tree
    diff_test(
        name = out_file.replace("/", "_").replace(".md", "-difftest"),
        failure_message = "Please run \"bazel run //docs:update\"",
        # Source file
        file1 = out_label,
        # Output from stardoc rule above
        file2 = out_file.replace(".md", "-docgen.md"),
    )

def update_docs(
        name = "update",
        docs_folder = "docs"):
    """Creates a `sh_binary` target which copies over generated doc files to the local source tree.

    This is to be used in tandem with `stardoc_with_diff_test()` to produce a convenient workflow
    for generating, testing, and updating all doc files as follows:

    ``` bash
    bazel build //{docs_folder}/... && bazel test //{docs_folder}/... && bazel run //{docs_folder}:update
    ```

    eg.

    ``` bash
    bazel build //docs/... && bazel test //docs/... && bazel run //docs:update
    ```

    Args:
        name: the name of the `sh_binary` target
        docs_folder: the name of the folder containing the doc files in the local source tree
    """
    content = ["#!/usr/bin/env bash", "cd ${BUILD_WORKSPACE_DIRECTORY}"]
    data = []
    for r in native.existing_rules().values():
        if r["kind"] == "stardoc":
            doc_gen = r["out"]
            if doc_gen.startswith(":"):
                doc_gen = doc_gen[1:]
            doc_dest = doc_gen.replace("-docgen.md", ".md")
            data.append(doc_gen)
            content.append("cp -fv bazel-bin/{0}/{1} {2}".format(docs_folder, doc_gen, doc_dest))

    update_script = name + ".sh"
    write_file(
        name = "gen_" + name,
        out = update_script,
        content = content,
    )

    native.sh_binary(
        name = name,
        srcs = [update_script],
        data = data,
    )
