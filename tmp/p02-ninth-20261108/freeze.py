import hashlib, json, os, subprocess
from datetime import datetime, timezone
from pathlib import Path
os.environ["GIT_OPTIONAL_LOCKS"] = "0"
out = Path(__file__).parent.resolve()
def git(*args):
    return subprocess.check_output(["git","-c","core.longpaths=true", *args])
def digest(value):
    return hashlib.sha256(value).hexdigest()
def stamp():
    return datetime.now(timezone.utc).isoformat()
def metadata(path):
    return path.st_size, path.st_mtime_ns, path.st_ino
def file_bytes(path):
    try:
        before = metadata(path.stat())
        with path.open("rb") as stream:
            sha = hashlib.file_digest(stream, "sha256").hexdigest()
        after = metadata(path.stat())
        return dict(bytes=before[0], sha256=sha, stable=before == after, metadata=after)
    except OSError as exc:
        return dict(error=type(exc).__name__)
def git_state():
    return dict(branch=git("branch","--show-current").decode().strip(),
                head=git("rev-parse","HEAD").decode().strip(),
                index=file_bytes(Path(os.fsdecode(git("rev-parse","--git-path","index").strip()))),
                stage_sha=digest(git("ls-files","--stage","-z")))
def inventory():
    groups = {}
    for label, args in [("tracked",["--cached"]),("untracked",["--others","--exclude-standard"])]:
        groups[label] = [p.decode("utf-8") for p in git("ls-files","-z",*args).split(b"\0") if p and not p.startswith(b"tmp/p02-ninth-20261108/")]
    return groups
start = stamp()
before = git_state()
paths = inventory()
files = {group:{name:file_bytes(Path(chr(92)*2+"?"+chr(92)+str(Path.cwd()/name))) for name in names} for group,names in paths.items()}
drift = []
for name, info in {**files["tracked"], **files["untracked"]}.items():
    try:
        actual = metadata(Path(chr(92)*2+"?"+chr(92)+str(Path.cwd()/name)).stat())
    except OSError:
        actual = None
    if ("metadata" in info and (info["metadata"] != actual or not info["stable"])) or ("metadata" not in info and (actual is not None or info["error"] != "FileNotFoundError")):
        drift.append(name)
after = git_state()
paths_after = inventory()
result = dict(start_utc=start,end_utc=stamp(),git_before=before,git_after=after,files=files,
              inventory_stable=paths==paths_after,drift=drift,
              tracked_missing=[name for name,info in files["tracked"].items() if "error" in info])
with (out/"WORKSPACE-FREEZE-LONGPATHS.json").open("x",encoding="utf-8") as stream:
    json.dump(result,stream,ensure_ascii=False,indent=2)
print(json.dumps({k:v for k,v in result.items() if k!="files"},ensure_ascii=False))

