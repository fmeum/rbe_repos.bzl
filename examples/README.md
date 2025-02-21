This examples demonstrates how a regular Java toolchain can be defined by a repo whose contents are fetched in a build rule, not a repo rule. 
It currently doesn't work on macOS since the relevant JDKs contain symlinks.

## Steps
1. Run `bazel build //src:gen` against a remote or disk cache.
2. Run `bazel clean --expunge`.
3. Run `bazel build //src:gen` again and observe that only a handful of small tools (curl, tar, etc.) are downloaded to the local host, but the JDK itself is not with BwoB enabled.
