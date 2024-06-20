_ROOT_MARKER_FILE = "__remote_repos_internal_root"

def _http_archive_impl(ctx):
    # type: (ctx) -> None
    root_file = ctx.actions.declare_file(_ROOT_MARKER_FILE)
    ctx.actions.run_shell(
        outputs = ctx.outputs.files + [root_file],
        command = """
        root_file=$1
        CURL=$2
        SHA256SUM=$3
        TAR=$4
        out_dir=$(dirname $root_file)
        # Delete output directories precreated by Bazel as they may be replaced by symlinks.
        rm -r $out_dir/*
        out=$out_dir/$(uuidgen).tar.gz
        trap 'rm -f $out' EXIT
        $CURL -sSLo $out {url}
        echo "{sha256}  $out" | $SHA256SUM --status --strict --check -
        # --touch prevents "Cannot utime: Operation not supported" errors.
        $TAR -xzf $out -C $out_dir --strip-components={strip_components} --touch
        touch $root_file
        """.format(
            url = ctx.attr.urls[0],
            sha256 = ctx.attr.sha256,
            strip_components = ctx.attr.strip_components,
        ),
        arguments = [ctx.actions.args().add(root_file).add(ctx.executable._curl).add(ctx.executable._sha256sum).add(ctx.executable._tar)],
        tools = [ctx.executable._curl, ctx.executable._sha256sum, ctx.executable._tar],
        progress_message = "Downloading and extracting {url}".format(url = ctx.attr.urls[0]),
        mnemonic = "HttpArchive",
        execution_requirements = {
            "requires-network": "",
            "supports-path-mapping": "",
        },
    )

http_archive = rule(
    implementation = _http_archive_impl,
    attrs = {
        "urls": attr.string_list(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "strip_components": attr.int(mandatory = True),
        "files": attr.output_list(mandatory = True),
        "_curl": attr.label(
            default = "@ape//:curl",
            cfg = "exec",
            executable = True,
        ),
        "_sha256sum": attr.label(
            default = "@ape//:sha256sum",
            cfg = "exec",
            executable = True,
        ),
        "_tar": attr.label(
            default = "@ape//:tar",
            cfg = "exec",
            executable = True,
        ),
    },
)
