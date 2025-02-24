_BUILD_FILE_PREFIX = """\
load(":_rbe_repos_internal_files.bzl", "glob", RBE_REPOS_INTERNAL_FILES = "FILES")
load("@rbe_repos.bzl//internal:http_archive.bzl", rbe_repos_internal_http_archive = "http_archive")

rbe_repos_internal_http_archive(
    name = "_rbe_repos_internal_http_archive",
    urls = {urls},
    sha256 = {sha256},
    strip_components = {strip_components},
    files = RBE_REPOS_INTERNAL_FILES,
)

"""

_FILES_BZL = """\
load("@rbe_repos.bzl//internal:glob.bzl", _glob = "glob")

FILES = {files}
glob = lambda *args, **kwargs: _glob(FILES, *args, **kwargs)
"""

def _remote_http_archive_impl(ctx):
    # type: (repository_ctx) -> None
    ctx.file("REPO.bazel")
    ctx.file("_rbe_repos_internal_files.bzl", _FILES_BZL.format(
        files = repr(ctx.attr.files),
    ))
    build_file_content = ctx.read(ctx.attr.build_file)
    for apparent, canonical in ctx.attr.repo_mapping.items():
        build_file_content = build_file_content.replace("\"@" + apparent + "\"", "\"@@" + canonical + "\"")
        build_file_content = build_file_content.replace("\"@" + apparent + "//", "\"@@" + canonical + "//")
    ctx.file("BUILD.bazel", _BUILD_FILE_PREFIX.format(
        urls = repr(ctx.attr.urls),
        sha256 = repr(ctx.attr.sha256),
        strip_components = repr(ctx.attr.strip_components),
    ) + build_file_content)

_remote_http_archive = repository_rule(
    implementation = _remote_http_archive_impl,
    attrs = {
        "urls": attr.string_list(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "strip_components": attr.int(mandatory = True),
        "build_file": attr.label(),
        "files": attr.string_list(mandatory = True),
        "repo_mapping": attr.string_dict(mandatory = True),
    },
)

def _rbe_repos_impl(ctx):
    # type: (module_ctx) -> extension_metadata
    http_archives = {}
    for module in ctx.modules:
        for http_archive in module.tags.http_archive:
            if not module.is_root or not ctx.is_dev_dependency(http_archive):
                fail("http_archive is only allowed in the root module with dev_dependency = True, got", http_archive)
            if http_archive.name in http_archives:
                fail("http_archive '{}' defined multiple times")
            http_archives[http_archive.name] = None

            download = ctx.download_and_extract(
                url = http_archive.urls,
                canonical_id = " ".join(http_archive.urls),
                integrity = http_archive.integrity,
                stripPrefix = http_archive.strip_prefix,
                output = http_archive.name,
            )

            if not http_archive.integrity:
                print(http_archive, " can set integrity =", repr(download.integrity))

            result = ctx.execute(["find", "-L", http_archive.name, "-type", "f"])
            if result.return_code != 0:
                fail("Failed to list files in http_archive", http_archive, ":", result.stderr)
            prefix = http_archive.name + "/"
            files = sorted([path.removeprefix(prefix) for path in result.stdout.splitlines()])

            _remote_http_archive(
                name = http_archive.name,
                urls = http_archive.urls,
                sha256 = download.sha256,
                strip_components = http_archive.strip_prefix.removesuffix("/").count("/") + 1,
                build_file = http_archive.build_file,
                files = files,
                repo_mapping = {label.name: label.repo_name for label in http_archive.bazel_deps}
            )

    return ctx.extension_metadata(
        root_module_direct_deps = [],
        root_module_direct_dev_deps = http_archives.keys(),
    )

_http_archive = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
        "urls": attr.string_list(mandatory = True),
        "integrity": attr.string(),
        "strip_prefix": attr.string(),
        "build_file": attr.label(),
        "bazel_deps": attr.label_list(),
    },
)

rbe_repos = module_extension(
    implementation = _rbe_repos_impl,
    tag_classes = {
        "http_archive": _http_archive,
    },
)
