"Macros for loading dependencies and registering toolchains"

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//lib/private:jq_toolchain.bzl", "JQ_PLATFORMS", "jq_host_alias_repo", "jq_platform_repo", "jq_toolchains_repo", _DEFAULT_JQ_VERSION = "DEFAULT_JQ_VERSION")
load("//lib/private:yq_toolchain.bzl", "YQ_PLATFORMS", "yq_host_alias_repo", "yq_platform_repo", "yq_toolchains_repo", _DEFAULT_YQ_VERSION = "DEFAULT_YQ_VERSION")

def aspect_bazel_lib_dependencies():
    "Load dependencies required by aspect rules"
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "c6966ec828da198c5d9adbaa94c05e3a1c7f21bd012a0b29ba8ddbccb2c93b0d",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.1.1/bazel-skylib-1.1.1.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.1.1/bazel-skylib-1.1.1.tar.gz",
        ],
    )

# Re-export the default versions
DEFAULT_JQ_VERSION = _DEFAULT_JQ_VERSION
DEFAULT_YQ_VERSION = _DEFAULT_YQ_VERSION

def register_jq_toolchains(name = "jq", version = DEFAULT_JQ_VERSION):
    """Registers jq toolchain and repositories

    Args:
        name: override the prefix for the generated toolchain repositories
        version: the version of jq to execute (see https://github.com/stedolan/jq/releases)
    """
    for [platform, meta] in JQ_PLATFORMS.items():
        jq_platform_repo(
            name = "%s_%s" % (name, platform),
            platform = platform,
            version = version,
        )
        native.register_toolchains("@%s_toolchains//:%s_toolchain" % (name, platform))

    jq_host_alias_repo(
        name = "%s_host" % name,
        user_repository_name = name,
    )

    jq_toolchains_repo(
        name = "%s_toolchains" % name,
        user_repository_name = name,
    )

def register_yq_toolchains(name = "yq", version = DEFAULT_YQ_VERSION):
    """Registers yq toolchain and repositories

    Args:
        name: override the prefix for the generated toolchain repositories
        version: the version of yq to execute (see https://github.com/mikefarah/yq/releases)
    """
    for [platform, meta] in YQ_PLATFORMS.items():
        yq_platform_repo(
            name = "%s_%s" % (name, platform),
            platform = platform,
            version = version,
        )
        native.register_toolchains("@%s_toolchains//:%s_toolchain" % (name, platform))

    yq_host_alias_repo(
        name = "%s_host" % name,
        user_repository_name = name,
    )

    yq_toolchains_repo(
        name = "%s_toolchains" % name,
        user_repository_name = name,
    )
