def glob(files, include, *, exclude = [], exclude_directories = True, allow_empty = False):
    # type: (list[string], list[string], list[string], bool, bool) -> List[str]
    if not exclude_directories:
        fail("exclude_directories is not supported by remote_repos.bzl")
    return []

