_NO_GLOB_MATCHES = "{glob} failed to match any files"

def _transitive_entries(directory):
    # type: (struct) -> list[struct|string]
    entries = [directory]
    stack = [directory]
    for _ in range(99999999):
        if not stack:
            return entries
        d = stack.pop()
        for entry in d.entries.values():
            entries.append(entry)
            if type(entry) != "string":
                stack.append(entry)

    fail("Should never get to here")

def _directory_glob_chunk(directory, chunk):
    # type: (struct, string) -> list[struct|string]
    if chunk == "*":
        return directory.entries.values()
    elif chunk == "**":
        return _transitive_entries(directory)
    elif "*" not in chunk:
        if chunk in directory.entries:
            return [directory.entries[chunk]]
        else:
            return []
    elif chunk.count("*") > 2:
        fail("glob chunks with more than two asterixes are unsupported. Got", chunk)

    if chunk.count("*") == 2:
        left, middle, right = chunk.split("*")
    else:
        middle = ""
        left, right = chunk.split("*")
    entries = []
    for name, entry in directory.entries.items():
        if name.startswith(left) and name.endswith(right) and len(left) + len(right) <= len(name) and middle in name[len(left):len(name) - len(right)]:
            entries.append(entry)
    return entries

def _directory_single_glob(directory, glob):
    # type: (struct) -> list[string]
    candidate_dirs = [directory]
    candidate_files = {}
    for chunk in glob.split("/"):
        next_candidate_dirs = {}
        candidate_files = {}
        for candidate in candidate_dirs:
            for e in _directory_glob_chunk(candidate, chunk):
                if type(e) == "string":
                    candidate_files[e] = None
                else:
                    next_candidate_dirs[e.path] = e
        candidate_dirs = next_candidate_dirs.values()

    return candidate_files.keys()

def _make_directory(files):
    root_directory = struct(
        entries = {},
        path = "",
    )
    for f in files:
        parts = f.split("/")
        d = root_directory
        for p in parts[:-1]:
            d = d.entries.setdefault(p, struct(
                entries = {},
                path = d.path + "/" + p,
            ))
        d.entries[parts[-1]] = f

    return root_directory

def glob(files, include, exclude = [], allow_empty = True):
    # type: (list[string], list[string], list[string], bool) -> list[string]
    root_directory = _make_directory(files)

    include_files = []
    for g in include:
        matches = _directory_single_glob(root_directory, g)
        if not matches and not allow_empty:
            fail(_NO_GLOB_MATCHES.format(glob = repr(g)))
        include_files.extend(matches)

    if not exclude:
        return include_files

    include_files = {k: None for k in include_files}
    for g in exclude:
        matches = _directory_single_glob(root_directory, g)
        if not matches and not allow_empty:
            fail(_NO_GLOB_MATCHES.format(glob = repr(g)))
        for f in matches:
            include_files.pop(f, None)
    return include_files.keys()
