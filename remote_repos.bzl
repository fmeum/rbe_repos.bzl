_BUILD_FILE_SUFFIX = """

load(":_remote_repos_internal_files.bzl", "glob", REMOTE_REPOS_INTERNAL_FILES = "FILES")
load("@remote_repos.bzl//internal:http_archive.bzl", remote_repos_internal_http_archive = "http_archive")

remote_repos_internal_http_archive(
    name = "_remote_repos_internal_http_archive",
    urls = {urls},
    sha256 = {sha256},
    strip_components = {strip_components},
    files = REMOTE_REPOS_INTERNAL_FILES,
)
"""

_FILES_BZL = """\
load("@remote_repos.bzl//internal:glob.bzl", _glob = "glob")
FILES = {files}
glob = lambda *args, **kwargs: _glob(FILES, *args, **kwargs)
"""

def _remote_http_archive_impl(ctx):
    # type: (repository_ctx) -> None
    ctx.file("REPO.bazel")
    ctx.file("_remote_repos_internal_files.bzl", _FILES_BZL.format(
        files = repr(ctx.attr.files),
    ))
    ctx.file("BUILD.bazel", ctx.read(ctx.attr.build_file) + _BUILD_FILE_SUFFIX.format(
        urls = repr(ctx.attr.urls),
        sha256 = repr(ctx.attr.sha256),
        strip_components = repr(ctx.attr.strip_components),
    ))

_remote_http_archive = repository_rule(
    implementation = _remote_http_archive_impl,
    attrs = {
        "urls": attr.string_list(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "strip_components": attr.int(mandatory = True),
        "build_file": attr.label(),
        "files": attr.string_list(mandatory = True),
    },
)

def _remote_repos_impl(ctx):
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
    },
)

remote_repos = module_extension(
    implementation = _remote_repos_impl,
    tag_classes = {
        "http_archive": _http_archive,
    },
)
