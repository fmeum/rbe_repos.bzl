def _http_archive_impl(ctx):
    # type: (ctx) -> None
    ctx.actions.run_shell(
        outputs = ctx.outputs.files,
        command = """
        out={out_dir}/$(uuidgen).tar.gz
        trap 'rm -f $out' ERR
        curl -sSLo $out {url}
        echo "{sha256}  $out" | sha256sum -c -
        tar -xzf $out -C {out_dir} --strip-components={strip_components}
        """.format(
            out_dir = ctx.bin_dir.path + "/" + ctx.label.package,
            url = ctx.attr.urls[0],
            sha256 = ctx.attr.sha256,
            strip_components = ctx.attr.strip_components,
        ),
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
