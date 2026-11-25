"""Check installed snapshots against the locked content trees of their source releases."""

import hashlib
import json
import os
from pathlib import Path
import stat
import sys

SKILL = Path(__file__).resolve().parents[1]
SOURCES = SKILL / "references/.upstream"
LOCK = SKILL / "references/sources.lock.json"


def git_digest(kind, data):
    header = f"{kind} {len(data)}\0".encode("ascii")
    digest = hashlib.sha1(usedforsecurity=False)
    digest.update(header)
    digest.update(data)
    return digest.digest()


def git_tree(directory, crlf_suffix):
    children = []
    file_count = 0
    for path in directory.iterdir():
        name = os.fsencode(path.name)
        mode = path.lstat().st_mode
        if stat.S_ISDIR(mode):
            digest, descendant_count = git_tree(path, crlf_suffix)
            git_mode = b"40000"
            sort_key = name + b"/"
            file_count += descendant_count
        else:
            git_mode, data = git_blob(path, mode, crlf_suffix)
            digest = git_digest("blob", data)
            sort_key = name
            file_count += 1
        children.append((sort_key, git_mode + b" " + name + b"\0" + digest))
    tree = b"".join(item for _, item in sorted(children))
    return git_digest("tree", tree), file_count


def git_blob(path, mode, crlf_suffix):
    if stat.S_ISREG(mode):
        data = path.read_bytes()
        if crlf_suffix and path.suffix == crlf_suffix:
            if b"\n" in data.replace(b"\r\n", b""):
                raise ValueError(f"Expected the upstream Windows line endings: {path}")
            data = data.replace(b"\r\n", b"\n")
        return (b"100755" if mode & stat.S_IXUSR else b"100644"), data
    if stat.S_ISLNK(mode):
        return b"120000", os.fsencode(os.readlink(path))
    raise ValueError(f"Unsupported filesystem entry: {path}")


def main():
    lock = json.loads(LOCK.read_text(encoding="utf-8"))
    failed = False
    for source in lock:
        base = SOURCES / source["directory"]
        try:
            if base.is_symlink() or not base.is_dir():
                raise ValueError("Missing snapshot directory")
            digest, count = git_tree(base, source.get("checkout_crlf_suffix"))
            expected_tree = source.get("distribution_tree", source["tree"])
            expected_files = source.get("distribution_files", source["files"])
            if digest.hex() != expected_tree or count != expected_files:
                raise ValueError(f"Expected {expected_tree} and {expected_files} files, found {digest.hex()} and {count}")
            for entrypoint in (source["license_file"], *source["entrypoints"]):
                if not (base / entrypoint).exists():
                    raise ValueError(f"Missing entry point: {entrypoint}")
        except (OSError, ValueError) as error:
            print(f"FAIL {source['directory']}: {error}", file=sys.stderr)
            failed = True
        else:
            version = source["commit"][:12] if "commit" in source else source["release"]
            print(f"OK {source['directory']} {version} ({count} files)")
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
