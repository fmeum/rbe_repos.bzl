load("@rules_java//java:defs.bzl", "java_runtime")

package(default_visibility = ["//visibility:public"])

exports_files(["WORKSPACE", "BUILD.bazel"])

filegroup(
    name = "jre",
    srcs = glob(
        [
            "jre/bin/**",
            "jre/lib/**",
        ],
        allow_empty = True,
        # In some configurations, Java browser plugin is considered harmful and
        # common antivirus software blocks access to npjp2.dll interfering with Bazel,
        # so do not include it in JRE on Windows.
        exclude = ["jre/bin/plugin2/**"],
    ),
)

filegroup(
    name = "jdk-bin",
    srcs = glob(
        ["bin/**"],
        # The JDK on Windows sometimes contains a directory called
        # "%systemroot%", which is not a valid label.
        exclude = ["**/*%*/**"],
    ),
)

# This folder holds security policies.
filegroup(
    name = "jdk-conf",
    srcs = glob(
        ["conf/**"],
        allow_empty = True,
    ),
)

filegroup(
    name = "jdk-include",
    srcs = glob(
        ["include/**"],
        allow_empty = True,
    ),
)

filegroup(
    name = "jdk-lib",
    srcs = glob(
        ["lib/**", "release"],
        allow_empty = True,
        exclude = [
            "lib/missioncontrol/**",
            "lib/visualvm/**",
        ],
    ),
)

java_runtime(
    name = "jdk",
    srcs = [
        ":jdk-bin",
        ":jdk-conf",
        ":jdk-include",
        ":jdk-lib",
        ":jre",
    ],
    # Provide the 'java` binary explicitly so that the correct path is used by
    # Bazel even when the host platform differs from the execution platform.
    # Exactly one of the two globs will be empty depending on the host platform.
    # When --incompatible_disallow_empty_glob is enabled, each individual empty
    # glob will fail without allow_empty = True, even if the overall result is
    # non-empty.
    java = glob(["bin/java.exe", "bin/java"], allow_empty = True)[0],
    version = 21,
)

filegroup(
    name = "jdk-jmods",
    srcs = glob(
        ["jmods/**"],
        allow_empty = True,
    ),
)

java_runtime(
    name = "jdk-with-jmods",
    srcs = [
        ":jdk-bin",
        ":jdk-conf",
        ":jdk-include",
        ":jdk-lib",
        ":jdk-jmods",
        ":jre",
    ],
    java = glob(["bin/java.exe", "bin/java"], allow_empty = True)[0],
    version = 21,
)