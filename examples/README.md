This examples demonstrates how a regular Java toolchain can be defined by a repo whose contents are fetched in a build rule, not a repo rule. 
It currently doesn't work on macOS since the relevant JDKs contain symlinks.

## Steps

1. Run `bazel build //src:gen` against a remote or disk cache.
2. Run `bazel clean --expunge`.
3. Run `bazel build //src:gen` again and observe that only a handful of small tools (curl, tar, etc.) are downloaded to the local host, but the JDK itself is not with BwoB enabled.

## How it works

A module extension downloads the archive eagerly and persists the list of files in the archive in `MODULE.bazel.lock`. 
A build rule patched in by the repo rule declares these files as outputs, which makes them accessible in the repos BUILD file as if they were source files.
The repo rule also transparently patches in a version of `glob` that can operate on these files.
The build rule uses `ape` binaries to download and extract the archive at execution time.
It also supports path mapping, which, if enabled, allows the action to be cached across different target platform.

## To do
 
Add support for authentication, perhaps by allowing users to register a "downloader toolchain". 
The local implementation of the toolchain could talk to the credential helper to receive authentication information out-of-band and without affecting the AC key.
A remote implementation could rely on "well-known" exec properties understood by the remote executor, which would provide the authentication information.
