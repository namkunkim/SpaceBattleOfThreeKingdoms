"""Create only the reviewed isolated source tree and verify import mutations."""
import json
import os
from pathlib import Path
import sys

sys.dont_write_bytecode = True
from prepare import HERE, RUN, ROOT, blob, digest, git_state, overlay

MANIFEST = json.loads((HERE / "source-manifest.json").read_text(encoding="utf-8"))


def safe_chain(path):
    for item in (path, *path.parents):
        if item.exists():
            attrs = getattr(item.lstat(), "st_file_attributes", 0)
            if item.is_symlink() or attrs & 0x400:
                raise RuntimeError(f"Reparse point in path: {item}")


def protect(label):
    actual = git_state()
    (RUN / f"protected-{label}.json").write_text(json.dumps(actual, indent=2), encoding="utf-8")
    assert actual == MANIFEST["git"]


def stage(project):
    assert not project.exists()
    assert not MANIFEST["unresolved_literal_refs"], MANIFEST["unresolved_literal_refs"]
    edits = overlay()
    for record in MANIFEST["source"]:
        name = record["name"]
        original = blob(name)
        assert digest(original) == record["sha256_head"]
        raw = edits[name].encode() if name in edits else original
        assert digest(raw) == record["sha256_project"]
        output = project / name
        safe_chain(output)
        output.parent.mkdir(parents=True, exist_ok=True)
        with output.open("xb") as file:
            file.write(raw)


def imported(project):
    expected = {row["name"]: row["sha256_project"] for row in MANIFEST["source"]}
    generated = {}
    for f in project.rglob("*"):
        safe_chain(f)
        if not f.is_file():
            continue
        relative = f.relative_to(project).as_posix()
        actual = digest(f.read_bytes())
        if relative in expected:
            before = expected.pop(relative)
            if before == actual:
                continue
            assert f.suffix == ".import", (relative, before, actual)
            # Only the editor-owned remap/dependency metadata may be rewritten.
            generated[relative] = {"before": before, "after": actual}
        else:
            assert relative.startswith(".godot/") or f.suffix in {".uid", ".import"}, relative
            generated[relative] = {"after": actual}
    assert not expected, expected
    assert (project / ".godot/global_script_class_cache.cfg").is_file()
    (RUN / "import-generated.json").write_text(json.dumps(generated, indent=2), encoding="utf-8")


def main():
    path = Path(sys.argv[1]).absolute()
    assert os.path.normcase(str(path)) == os.path.normcase(str(RUN)), path
    safe_chain(path)
    if sys.argv[2:] == ["--protected"]:
        protect("after")
        return
    if sys.argv[2:] == ["--after-import"]:
        protect("after-import")
        imported(path / "project")
        return
    assert not sys.argv[2:]
    protect("before")
    stage(path / "project")


if __name__ == "__main__":
    main()
