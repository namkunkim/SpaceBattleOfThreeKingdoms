"""Build a Windows PC executable bound to the exported checkpoint scripts."""
import argparse
import configparser
from contextlib import contextmanager
import hashlib
import json
import re
import struct
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "core/battle/"
MANIFEST = "data/operation_checkpoint_fingerprint.json"
ANCHOR = "data/operation_checkpoint_anchor.gd"
REPLAY_MANIFEST = "data/first_operation_replay_fingerprint.json"
PRESET = "Windows PC (fingerprint staging)"
RELEASE_GATE = '"res://tools/USE-build_fingerprinted_windows.py-for-Windows-release.exe"'

DEBUG_GATE = '"res://tools/USE-build_fingerprinted_windows.py--debug.exe"'


@contextmanager
def staging_preset():
    path = ROOT / "export_presets.cfg"
    lock = path.with_suffix(".cfg.o07-build-lock")
    with lock.open("xb"):
        pass
    try:
        original = path.read_bytes()
        config = configparser.ConfigParser(interpolation=None)
        config.read_string(original.decode("utf-8-sig"))
        sections = [s for s in config.sections() if re.fullmatch(r"preset\.\d+", s)]
        official, = [s for s in sections if config[s].get("name") == '"Windows PC"']
        options = dict(config[official + ".options"])
        if options["custom_template/release"] != RELEASE_GATE:
            raise RuntimeError("Windows PC release preset is missing its fingerprint gate")
        if options["custom_template/debug"] != DEBUG_GATE:
            raise RuntimeError("Windows PC debug preset is missing its fingerprint gate")
        next_index = max(int(s.split(".")[1]) for s in sections) + 1
        preset = dict(config[official])
        preset.update(name=json.dumps(PRESET), runnable="false", export_path='""')
        options["custom_template/release"] = '""'
        options["custom_template/debug"] = '""'
        suffix = []
        for section, values in ((f"preset.{next_index}", preset),
                                (f"preset.{next_index}.options", options)):
            suffix.append(f"[{section}]")
            suffix.extend(f"{key}={value}" for key, value in values.items())
            suffix.append("")
        appended = original + ("\n\n" + "\n".join(suffix)).encode("utf-8")
        path.write_bytes(appended)
        try:
            yield
        finally:
            if path.read_bytes() != appended:
                raise RuntimeError("Export presets changed during the Windows build")
            path.write_bytes(original)
    finally:
        lock.unlink()


class Pack:
    """Read the unencrypted Godot 4.7 PCK v4 format used by this preset."""

    def __init__(self, path):
        self.path = path
        self.entries = {}
        with path.open("rb") as f:
            start = 0
            if f.read(4) != b"GDPC":
                f.seek(-12, 2)
                length, magic = struct.unpack("<Q4s", f.read(12))
                if magic != b"GDPC" or length > f.tell() - 12:
                    raise ValueError(f"Missing embedded PCK in {path}")
                start = f.tell() - 12 - length
            f.seek(start)
            magic, format_, major, minor, _patch, flags, base, directory = struct.unpack(
                "<4sIIIIIQQ", f.read(40))
            if (magic, format_, major, minor, flags) != (b"GDPC", 4, 4, 7, 2):
                raise ValueError(f"Unexpected PCK format in {path}")
            f.seek(start + directory)
            count, = struct.unpack("<I", f.read(4))
            if count > 100_000:
                raise ValueError(f"Invalid file count in {path}")
            for _ in range(count):
                length, = struct.unpack("<I", f.read(4))
                if not 0 < length <= 4096:
                    raise ValueError(f"Invalid path length in {path}")
                name = f.read(length).rstrip(b"\0").decode("utf-8").removeprefix("res://")
                offset, size, _, entry_flags = struct.unpack("<QQ16sI", f.read(36))
                if entry_flags or name in self.entries or base + offset + size > directory:
                    raise ValueError(f"Unexpected PCK entry {name}")
                self.entries[name] = (start + base + offset, size)

    def read(self, path):
        offset, size = self.entries[path]
        with self.path.open("rb") as f:
            f.seek(offset)
            return f.read(size)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def source_digests():
    owner = (ROOT / PREFIX / "operation_private_state.gd").read_text(encoding="utf-8")
    match = re.search(r"^const CODE := (\[.*\])$", owner, re.MULTILINE)
    names = json.loads(match[1])
    return {name: sha((ROOT / PREFIX / name).read_bytes()) for name in names}

def run_export(godot, action, out, log):
    with log.open("wb") as stream:
        subprocess.run([godot, "--headless", "--path", ROOT, action, PRESET, out],
                       cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT, check=True)
    if b"ERROR:" in log.read_bytes():
        raise RuntimeError(f"Export errors in {log}")

def pack_fingerprints(pack, names, suffix):
    return {name: sha(pack.read(PREFIX + name + suffix)) for name in names}

def replay_source_digests():
    battle = ROOT / PREFIX
    return {path.relative_to(battle).as_posix(): sha(path.read_bytes())
            for path in sorted(battle.rglob("*.gd")) if path.is_file()}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--debug", action="store_true", help="use the Windows debug template")
    parser.add_argument("godot", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    godot = args.godot.resolve(strict=True)
    out = args.output.resolve()
    if out.exists():
        raise FileExistsError(out)
    work = out.with_name(out.name + ".building")
    work.mkdir(parents=True, exist_ok=False)
    with staging_preset():
        digest, count = build(godot, work, debug=args.debug)
    work.rename(out)
    print(f"FINGERPRINT_BUILD_PASS {count} scripts, zero raw GDScript files, manifest {digest}")

def build(godot, out, debug=False):
    sources = source_digests()
    replay_sources = replay_source_digests()
    evidence = out / "_build"
    evidence.mkdir()
    stage_file = evidence / "stage.pck"
    run_export(godot, "--export-pack", stage_file, evidence / "export-stage.log")
    stage = Pack(stage_file)
    if any(name.endswith(".gd") for name in stage.entries):
        raise RuntimeError("Stage unexpectedly contains source")
    if source_digests() != sources or replay_source_digests() != replay_sources:
        raise RuntimeError("Checkpoint sources changed during staging")
    version = subprocess.check_output([godot, "--version"], text=True).strip().split(".")
    fingerprint = {
        "format": "operation-checkpoint-fingerprint/1",
        "engine": ".".join([*version[:4], version[-1]]),
        "sources": sources,
        "tokens": pack_fingerprints(stage, sources, "c"),
        "remaps": pack_fingerprints(stage, sources, ".remap"),
    }
    encoded = json.dumps(fingerprint, ensure_ascii=True, separators=(",", ":")).encode("ascii")
    anchor = f'extends RefCounted\n\nconst SHA256 := "{sha(encoded)}"\n'.encode("ascii")
    replay = {
        "format": "first-operation-replay-fingerprint/1",
        "engine": fingerprint["engine"],
        "sources": replay_sources,
        "tokens": pack_fingerprints(stage, replay_sources, "c"),
        "remaps": pack_fingerprints(stage, replay_sources, ".remap"),
    }
    replay_encoded = json.dumps(replay, ensure_ascii=True, separators=(",", ":")).encode("ascii")
    anchor += f'const REPLAY_SHA256 := "{sha(replay_encoded)}"\n'.encode("ascii")
    output = out / "SpaceBattleOfThreeKingdoms.exe"
    generated = []
    try:
        for name, content in ((MANIFEST, encoded), (REPLAY_MANIFEST, replay_encoded), (ANCHOR, anchor)):
            path = ROOT / name
            with path.open("xb") as stream:
                generated.append(path)
                stream.write(content)
        action = "--export-debug" if debug else "--export-release"
        run_export(godot, action, output, evidence / "export-final.log")
        final = Pack(output)
        if source_digests() != sources or replay_source_digests() != replay_sources:
            raise RuntimeError("Checkpoint sources changed during Windows export")
        if final.read(MANIFEST) != encoded or final.read(REPLAY_MANIFEST) != replay_encoded or any(p.endswith(".gd") for p in final.entries):
            raise RuntimeError("Unexpected manifest or source in Windows PCK")
        for suffix in ("c", ".remap"):
            if pack_fingerprints(stage, replay_sources, suffix) != pack_fingerprints(final, replay_sources, suffix):
                raise RuntimeError("Token or remap changed between export passes")
        if ANCHOR + "c" not in final.entries or ANCHOR + ".remap" not in final.entries:
            raise RuntimeError("Missing tokenized fingerprint anchor")
    finally:
        for path in generated:
            path.unlink()
        if ROOT / ANCHOR in generated:
            (ROOT / (ANCHOR + ".uid")).unlink(missing_ok=True)
    verify_log = evidence / "verify-final.log"
    with verify_log.open("wb") as stream:
        subprocess.run([godot, "--headless", "--path", ROOT, "--script",
                        "res://tools/verify_windows_checkpoint_fingerprint.gd", "--", output],
                       cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT, check=True)
    result = verify_log.read_bytes()
    if b"ERROR:" in result or b"FINGERPRINT_RUNTIME_VERIFY_PASS" not in result:
        raise RuntimeError(f"Fingerprint runtime verification failed in {verify_log}")
    (evidence / "fingerprint.json").write_bytes(encoded)
    (evidence / "replay-fingerprint.json").write_bytes(replay_encoded)
    return sha(encoded), len(sources)

if __name__ == "__main__":
    main()

