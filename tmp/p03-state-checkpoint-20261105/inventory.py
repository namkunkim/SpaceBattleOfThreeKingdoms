"""Read-only inventory for the P03 GDScript declaration subset."""

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import stat
import sys


FORMAT = "p03/declarations/1"
WORD = r"[A-Za-z_]\w*"
MEMBER = re.compile(rf"(static )?var ({WORD})\s*(.*)", re.DOTALL)
FUNCTION = re.compile(rf"(?:static )?func {WORD}\s*\(.*\)\s*(?:->\s*[\w.\[\], ]+)?\s*:", re.DOTALL)
TYPE = re.compile(rf"{WORD}(?:\.{WORD})*(?:\s*\[[\w., \[\]]+\])?")
INNER_PATH = "core/battle/battle_state.gd"


class InventoryError(ValueError):
    pass


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise InventoryError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def encode(data):
    return (json.dumps(data, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def parse_json(data):
    return json.loads(data.decode("utf-8"), object_pairs_hook=unique_object)


def logical_lines(path, data):
    """Yield indentation, first line, comment-free syntax, and literal text."""
    source = data.decode("utf-8")
    if source.startswith("\ufeff") or "\x00" in source or "\r" in source.replace("\r\n", ""):
        raise InventoryError(f"{path}: unsupported source encoding or line ending")
    stack = []
    raw = []
    cleaned = []
    indent = 0
    start = 0
    continuation = False
    used_continuation = False
    semicolon = False
    top_punctuation = []
    pairs = {")": "(", "]": "[", "}": "{"}
    for number, line in enumerate(source.replace("\r\n", "\n").split("\n"), 1):
        if continuation:
            stripped_next = line.lstrip("\t")
            if (not stripped_next.strip() or stripped_next.lstrip().startswith("#")
                    or len(line) - len(stripped_next) < indent):
                raise InventoryError(f"{path}:{number}: expected indented code after backslash")
        continuation = False
        if not raw:
            stripped = line.lstrip(" \t")
            if not stripped or stripped.startswith("#"):
                continue
            leading = line[:len(line) - len(stripped)]
            if " " in leading:
                raise InventoryError(f"{path}:{number}: only tab indentation is supported")
            indent, start = len(leading), number
        raw.append(line)
        quote = None
        escaped = False
        end = len(line)
        for index, char in enumerate(line):
            if quote:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == quote:
                    quote = None
                continue
            if char == "#":
                end = index
                break
            if char in "\"'":
                if line[index:index + 3] == char * 3:
                    raise InventoryError(f"{path}:{number}: triple-quoted string")
                quote = char
            elif char == "\\":
                if line[index + 1:].strip():
                    raise InventoryError(f"{path}:{number}: nonterminal backslash")
                end = index
                continuation = used_continuation = True
                break
            elif char in "([{":
                stack.append(char)
            elif char == ";" and not stack:
                semicolon = True
            elif char in ":=" and not stack:
                top_punctuation.append(char)
            elif char in pairs and (not stack or stack.pop() != pairs[char]):
                raise InventoryError(f"{path}:{number}: mismatched delimiter")
        if quote:
            raise InventoryError(f"{path}:{number}: unclosed string")
        cleaned.append(line[:end])
        if not stack and not continuation:
            yield (indent, start, "\n".join(cleaned).strip(), "\n".join(raw),
                   used_continuation, semicolon, "".join(top_punctuation))
            raw.clear()
            cleaned.clear()
            used_continuation = False
            semicolon = False
            top_punctuation.clear()
    if raw:
        raise InventoryError(f"{path}:{start}: unclosed delimiter")


def member_tail(tail):
    if not tail:
        return True
    if tail.startswith(":="):
        return bool(tail[2:].strip()) and not tail.endswith(":")
    if tail.startswith("="):
        return bool(tail[1:].strip()) and not tail.endswith(":")
    if not tail.startswith(":"):
        return False
    annotation, equal, initializer = tail[1:].partition("=")
    type_name = annotation.strip()
    return type_name not in {"get", "set"} and bool(TYPE.fullmatch(type_name)) and (
        not equal or bool(initializer.strip()) and not initializer.endswith(":")
    )


def declarations(path, data):
    root_scope = PurePosixPath(path).stem
    inner = None
    inner_names = set()
    members = []
    names = set()
    depth = 0
    previous_block = False
    function_depth = None
    named = False
    started = False
    for indent, line, code, raw, continuation, semicolon, punctuation in logical_lines(path, data):
        location = f"{path}:{line}"
        if previous_block and indent != depth + 1:
            raise InventoryError(f"{location}: missing indented block")
        if indent > depth and (not previous_block or indent != depth + 1):
            raise InventoryError(f"{location}: unsupported indentation")
        depth = indent
        previous_block = False
        if function_depth is not None:
            if indent > function_depth:
                previous_block = code.endswith(":")
                continue
            function_depth = None
        if continuation:
            raise InventoryError(f"{location}: class-level backslash")
        if semicolon:
            raise InventoryError(f"{location}: class-level statement separator")
        if indent == 0:
            inner = None
        elif indent != 1 or inner is None:
            raise InventoryError(f"{location}: unexpected class indentation")

        if match := re.fullmatch(rf"class_name ({WORD})", code):
            if indent or started or named:
                raise InventoryError(f"{location}: unexpected class_name")
            root_scope, named = match[1], True
            continue
        if match := re.fullmatch(rf"class ({WORD}):", code):
            if indent or path != INNER_PATH or match[1] not in {"Missile", "Swarm"} or match[1] in inner_names:
                raise InventoryError(f"{location}: unsupported inner class")
            inner = match[1]
            inner_names.add(inner)
            started = previous_block = True
            continue
        if match := MEMBER.fullmatch(code):
            if punctuation.count(":") > 1 or "=:" in punctuation or not member_tail(match[3]):
                raise InventoryError(f"{location}: unsupported member declaration")
            scope = f"{root_scope}.{inner}" if inner else root_scope
            identity = (scope, match[2])
            if identity in names:
                raise InventoryError(f"{location}: duplicate member {match[2]}")
            names.add(identity)
            members.append({"scope": scope, "name": match[2], "static": bool(match[1]), "line": line, "raw": raw})
            started = True
            continue
        if FUNCTION.match(code):
            header = FUNCTION.match(code)
            previous_block = header.end() == len(code)
            if previous_block:
                function_depth = indent
            started = True
            continue
        if re.fullmatch(rf"extends (?:{WORD}(?:\.{WORD})*|\"[^\"]+\"|'[^']+')", code):
            continue
        if re.fullmatch(rf"const {WORD}\s*(?::\s*[\w.\[\], ]*)?=\s*\S.*", code, re.DOTALL):
            started = True
            continue
        if re.fullmatch(rf"signal {WORD}(?:\s*\(.*\))?|enum(?: {WORD})?\s*\{{.*\}}", code, re.DOTALL):
            started = True
            continue
        raise InventoryError(f"{location}: unsupported class statement")
    if previous_block:
        raise InventoryError(f"{path}: missing block at end of file")
    return members


def ensure_plain(path, directory=False):
    info = path.lstat()
    reparse = getattr(info, "st_file_attributes", 0) & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0)
    expected = stat.S_ISDIR if directory else stat.S_ISREG
    if reparse or not expected(info.st_mode):
        raise InventoryError(f"{path}: expected plain {'directory' if directory else 'file'}")


def source_paths(root):
    core = root / "core"
    ensure_plain(core, directory=True)
    battle = core / "battle"
    ensure_plain(battle, directory=True)
    paths = []
    pending = [battle]
    while pending:
        for child in pending.pop().iterdir():
            if child.is_symlink() or (hasattr(child, "is_junction") and child.is_junction()):
                raise InventoryError(f"{child}: symbolic link or junction")
            if child.is_dir():
                ensure_plain(child, directory=True)
                pending.append(child)
            elif child.suffix.lower() == ".gd":
                ensure_plain(child)
                paths.append(child.relative_to(root).as_posix())
    return sorted(paths)


def read_plain(path):
    ensure_plain(path)
    return path.read_bytes()


def collect(root):
    paths = source_paths(root)
    files = []
    for path in paths:
        data = read_plain(root / path)
        files.append({"path": path, "sha256": sha256(data), "members": declarations(path, data)})
    if paths != source_paths(root):
        raise InventoryError("source path set changed during scan")
    for item in files:
        if sha256(read_plain(root / item["path"])) != item["sha256"]:
            raise InventoryError(f"{item['path']}: source bytes changed during scan")
    if paths != source_paths(root):
        raise InventoryError("source path set changed during verification")
    return {"format": FORMAT, "files": files}


def validate_baseline(doc):
    if not isinstance(doc, dict) or set(doc) != {"format", "files"} or doc["format"] != FORMAT:
        raise InventoryError("invalid baseline envelope")
    if not isinstance(doc["files"], list):
        raise InventoryError("invalid baseline files")
    previous_path = ""
    for item in doc["files"]:
        if not isinstance(item, dict) or set(item) != {"path", "sha256", "members"}:
            raise InventoryError("invalid baseline file")
        path = item["path"]
        if (not isinstance(path, str) or not path.startswith("core/battle/")
                or not path.lower().endswith(".gd") or "\\" in path or ":" in path
                or any(part in {"", ".", ".."} for part in path.split("/"))
                or path <= previous_path):
            raise InventoryError("invalid baseline path, duplicate, or order")
        previous_path = path
        if not isinstance(item["sha256"], str) or not re.fullmatch(r"[a-f0-9]{64}", item["sha256"]):
            raise InventoryError("invalid baseline SHA256")
        if not isinstance(item["members"], list):
            raise InventoryError("invalid baseline members")
        names = set()
        last_line = 0
        for member in item["members"]:
            if not isinstance(member, dict) or set(member) != {"scope", "name", "static", "line", "raw"}:
                raise InventoryError("invalid baseline member")
            if (not isinstance(member["scope"], str) or not re.fullmatch(rf"{WORD}(?:\.{WORD})?", member["scope"])
                    or not isinstance(member["name"], str) or not re.fullmatch(WORD, member["name"])
                    or type(member["static"]) is not bool or type(member["line"]) is not int
                    or member["line"] <= last_line or not isinstance(member["raw"], str) or not member["raw"]):
                raise InventoryError("invalid baseline member type or order")
            identity = (member["scope"], member["name"])
            if identity in names:
                raise InventoryError("duplicate baseline member")
            names.add(identity)
            last_line = member["line"]
    return doc


def compare(before, after):
    old = {f["path"]: f for f in before["files"]}
    new = {f["path"]: f for f in after["files"]}
    changes = []
    for path in sorted(old.keys() | new.keys()):
        if path not in old or path not in new:
            changes.append({"path": path, "file": "added" if path in new else "removed"})
            continue
        left = {(m["scope"], m["name"]): m for m in old[path]["members"]}
        right = {(m["scope"], m["name"]): m for m in new[path]["members"]}
        changed = [key for key in right if key in left and
                   (left[key]["raw"], left[key]["static"]) != (right[key]["raw"], right[key]["static"])]
        added = [key for key in right if key not in left]
        removed = [key for key in left if key not in right]
        order = [key for key in left if key in right] != [key for key in right if key in left]
        if changed or added or removed or order or old[path]["sha256"] != new[path]["sha256"]:
            changes.append({"path": path, "sha_drift": old[path]["sha256"] != new[path]["sha256"],
                            "added": added, "removed": removed, "changed": changed, "order_changed": order})
    return changes


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_subparsers(dest="mode", required=True)
    for mode in ("collect", "check"):
        command = modes.add_parser(mode)
        command.add_argument("--root", required=True, type=Path)
        if mode == "check":
            command.add_argument("--baseline", required=True, type=Path)
    args = parser.parse_args(argv)
    try:
        baseline_bytes = read_plain(args.baseline) if args.mode == "check" else None
        baseline = validate_baseline(parse_json(baseline_bytes)) if baseline_bytes is not None else None
        current = collect(args.root.absolute())
        if baseline is not None:
            if read_plain(args.baseline) != baseline_bytes:
                raise InventoryError("baseline bytes changed during scan")
            changes = compare(baseline, current)
            payload = {"equal": not changes, "changes": changes}
            status = int(bool(changes))
        else:
            payload, status = current, 0
        output = encode(payload)
    except (OSError, ValueError, RecursionError) as error:
        print(f"inventory: {error}", file=sys.stderr)
        return 2
    sys.stdout.buffer.write(output)
    return status


if __name__ == "__main__":
    raise SystemExit(main())
