"""Preservation preflight for the independently reviewed cursor/drain plan."""
import hashlib
import json
import os
from pathlib import Path
import stat
import sys

from launch import HERE, ROOT, PLAN_SHA, hashes, snapshot, sources, write_json

REVISION = HERE / "PLAN-PRESERVATION-REVISION.md"
REVISION_SHA = "0567c1306e14b142e82d3ad8f271a43c2530ca06ba200a7be517da991c3fdfd9"
P02_DOCS = ROOT / "docs/battle-core/pc-campaign-design"
PRODUCTION = ("assets", "core", "data", "feature_profiles", "hud", "input", "scenes",
              "script_templates", "scripts", "tests", "text_editor_themes", "tools", "view")
TRACE_RELATIVE = Path("roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms/battle_traces")
TRACE_PARENTS = tuple(ROOT / "tmp/p02-eighth-20261108/gate-k1" / mode / TRACE_RELATIVE
                      for mode in ("before-world-clean", "before-world-returning"))


def validate_path(path):
    if path.resolve(strict=True) != path:
        raise ValueError(f"noncanonical path: {path}")
    for component in (path, *path.parents):
        attributes = component.lstat().st_file_attributes
        if attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT:
            raise ValueError(f"reparse point: {component}")


def protection_roots():
    return sorted(set(
        [ROOT / path for path in PRODUCTION]
        + list((ROOT / "tmp").glob("p02-*"))
        + [P02_DOCS]
        + list(TRACE_PARENTS)
    ))


def inventory(roots, digest=True):
    found = {}

    def on_error(error):
        raise error

    for root in roots:
        validate_path(root)
        for folder, dirs, files in os.walk(root, onerror=on_error, followlinks=False):
            path = Path(folder)
            found[str(path)] = {"type": "directory"}
            for name in sorted(dirs + files):
                child = path / name
                key = str(child)
                if key in found:
                    continue
                metadata = child.lstat()
                if metadata.st_file_attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT:
                    raise ValueError(f"protected reparse point: {child}")
                if stat.S_ISDIR(metadata.st_mode):
                    found[key] = {"type": "directory"}
                elif stat.S_ISREG(metadata.st_mode):
                    record = {"type": "file", "bytes": metadata.st_size}
                    if digest:
                        with child.open("rb") as handle:
                            record["sha256"] = hashlib.file_digest(handle, "sha256").hexdigest()
                        current = child.stat()
                        if (metadata.st_size, metadata.st_mtime_ns) != (current.st_size, current.st_mtime_ns):
                            raise ValueError(f"file changed during inventory: {child}")
                    found[key] = record
                else:
                    raise ValueError(f"unexpected protected file type: {child}")
    return found


def protection_failures(before, after, attributable_p02_paths, own_dir):
    failures = []
    permitted = []
    for name, old in before.items():
        if after.get(name) != old:
            failures.append({"path": name, "reason": "existing protected entry changed or disappeared"})
    for name in sorted(after.keys() - before.keys()):
        path = Path(name)
        if (after[name]["type"] != "file" or path.parent not in TRACE_PARENTS
                or not path.match("battle-*.jsonl") or name not in attributable_p02_paths
                or path.is_relative_to(own_dir)):
            failures.append({"path": name, "reason": "new protected entry lacks approved pattern or provenance"})
        else:
            permitted.append({"path": name, **after[name], "provenance": attributable_p02_paths[name]})
    return failures, permitted


def protected_warnings(folder, roots, phase="start"):
    warnings = (folder / f"{phase}-status-stderr.bin").read_text(encoding="utf-8", errors="replace")
    matches = []
    for line in warnings.splitlines():
        if "could not open directory '" not in line:
            continue
        quoted = line.split("could not open directory '", 1)[1].split("':", 1)[0]
        path = ROOT / quoted
        if any(path.is_relative_to(root) or root.is_relative_to(path) for root in roots):
            matches.append(line)
    return matches


def main():
    if sum(path.is_dir() and (path / "run.json").is_file() for path in HERE.glob("attempt-*")) != 3:
        raise ValueError("unexpected prior-attempt count")
    folder = HERE / "attempt-04"
    validate_path(HERE)
    folder.mkdir(exist_ok=False)
    validate_path(folder)
    errors = []
    roots = protection_roots()
    fixed = []
    try:
        snapshot(folder, "start")
        fixed = sorted(set(sources() + [Path(__file__).resolve(), REVISION,
                                      HERE / "REVIEW-PRESERVATION-REVISION-V2-TERRA.md"]))
        for path in fixed:
            validate_path(path)
        values, errors = hashes(fixed)
        write_json(folder / "input-before.json", values)
        if values.get(str(REVISION), {}).get("sha256") != REVISION_SHA:
            errors.append("approved preservation plan SHA mismatch")
        if values.get(str(HERE / "PLAN.md"), {}).get("sha256") != PLAN_SHA:
            errors.append("approved functional plan SHA mismatch")
        errors.extend(protected_warnings(folder, roots))
        # Do not proceed to capture an incomplete baseline when porcelain reports
        # inaccessible directories inside a protected root.
        if not errors:
            protected = inventory(roots)
            write_json(folder / "protected-before.json", protected)
            values_now, rehash_errors = hashes(fixed)
            errors.extend(rehash_errors)
            if values_now != values:
                errors.append("fixed inputs changed during preflight")
    except (OSError, RuntimeError, ValueError) as exc:
        errors.append(str(exc))

    write_json(folder / "preservation-preflight.json", {
        "errors": errors, "input_count": len(fixed), "protected_roots": [str(root) for root in roots],
        "prior_executions": 3, "actual_exit": None, "engine_started": False,
        "gate_passed": False,
    })
    if errors:
        print(json.dumps(errors, indent=2))
        return 2
    # A passing baseline must be handed to the integrated process/exit gate.
    # This entry point only reserves and checks a fresh baseline.
    return 0


if __name__ == "__main__":
    sys.exit(main())
