def _http_archive_impl(ctx):
    # type: (ctx) -> None
    out_dir = (ctx.bin_dir.path + "/" + ctx.label.workspace_root + "/" + ctx.label.package).removesuffix("/")
    ctx.actions.run_shell(
        outputs = ctx.outputs.files,
        command = """
        # Delete output directories precreated by Bazel as they may be replaced by symlinks.
        echo "$PWD"
        rm -r {out_dir}/*
        out={out_dir}/$(uuidgen).tar.gz
        trap 'rm -f $out' EXIT
        curl -sSLo $out {url}
        echo "{sha256}  $out" | shasum --status --strict --check -
        tar -xzvf $out -C {out_dir} --strip-components={strip_components}
        ls -R $PWD/{out_dir}
        """.format(
            out_dir = out_dir,
            url = ctx.attr.urls[0],
            sha256 = ctx.attr.sha256,
            strip_components = ctx.attr.strip_components,
        ),
        progress_message = "Downloading and extracting {url}".format(url = ctx.attr.urls[0]),
        mnemonic = "HttpArchive",
        execution_requirements = {"requires-network": ""},
    )

http_archive = rule(
    implementation = _http_archive_impl,
    attrs = {
        "urls": attr.string_list(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "strip_components": attr.int(mandatory = True),
        "files": attr.output_list(mandatory = True),
    },
)
