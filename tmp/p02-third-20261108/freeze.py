import hashlib, json, os, pathlib, subprocess
ROOT=pathlib.Path("tmp/p02-third-20261108")
ENV=dict(os.environ,GIT_OPTIONAL_LOCKS="0")
def git(*args):
    r=subprocess.run(("git",*args),capture_output=True,env=ENV)
    if r.returncode: raise RuntimeError((args,r.returncode,r.stderr))
    return r.stdout
def entries(*args):
    return {x.decode("utf-8") for x in git("ls-files","-z",*args).split(b"\0") if x and not x.startswith(b"tmp/p02-third-20261108/")}
index=git("ls-files","--stage","-z")
branch=git("symbolic-ref","--short","HEAD")
head=git("rev-parse","HEAD")
tracked=entries("--cached")
untracked=entries("--others","--exclude-standard")
files={}
for name in sorted(tracked|untracked):
    p=pathlib.Path(name)
    if not p.is_file():
        files[name]={"kind":"tracked" if name in tracked else "untracked","missing":True}
        continue
    with p.open("rb") as f:
        start=os.fstat(f.fileno())
        h=hashlib.file_digest(f,"sha256").hexdigest()
        end=os.fstat(f.fileno())
    if (start.st_size,start.st_mtime_ns)!=(end.st_size,end.st_mtime_ns):
        raise RuntimeError(f"Changed during hashing: {name}")
    files[name]={"kind":"tracked" if name in tracked else "untracked","bytes":end.st_size,"sha256":h}
assert tracked==entries("--cached") and untracked==entries("--others","--exclude-standard")
assert (index,branch,head)==(git("ls-files","--stage","-z"),git("symbolic-ref","--short","HEAD"),git("rev-parse","HEAD"))
(ROOT/"index.stage.z").write_bytes(index)
(ROOT/"baseline-files.json").write_text(json.dumps(files,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
diff=subprocess.run(("git","diff","--check"),capture_output=True,env=ENV)
(ROOT/"diff-check.stdout").write_bytes(diff.stdout)
(ROOT/"diff-check.stderr").write_bytes(diff.stderr)
cache=pathlib.Path(".godot/global_script_class_cache.cfg").read_bytes()
summary=dict(branch=branch.decode().strip(),head=head.decode().strip(),index_sha256=hashlib.sha256(index).hexdigest(),index_file_sha256=hashlib.sha256(pathlib.Path(os.fsdecode(git("rev-parse","--git-path","index").strip())).read_bytes()).hexdigest(),tracked=len(tracked),untracked=len(untracked),missing=sum(x.get("missing",False) for x in files.values()),diff_check_exit=diff.returncode,cache_sha256=hashlib.sha256(cache).hexdigest(),excluded="current evidence root and Git-standard ignored paths, with canonical class cache fingerprinted separately")
(ROOT/"baseline-context.json").write_text(json.dumps(summary,indent=2)+"\n",encoding="utf-8")
print(summary)
