from pathlib import Path
import hashlib,json,os,subprocess,sys
e=Path("tmp/p02-third-20261108")
out=e/"closeout"
before=json.loads((e/"post-baseline-files.json").read_text(encoding="utf8"))
context=json.loads((e/"pre-baseline-context.json").read_text(encoding="utf8"))
proof=json.loads((out/"document-proof.json").read_text(encoding="utf8"))
env=dict(os.environ,GIT_OPTIONAL_LOCKS="0")
def git(*args):
 r=subprocess.run(("git",*args),env=env,capture_output=True)
 assert r.returncode==0,(args,r.stderr)
 return r.stdout
def sha(path):
 with Path(path).open("rb") as file: return hashlib.file_digest(file,"sha256").hexdigest()
def paths(*args):
 return {x.decode("utf8") for x in git("ls-files","-z",*args).split(b"\0") if x and not x.startswith(b"tmp/p02-third-20261108/")}
tracked=paths("--cached")
untracked=paths("--others","--exclude-standard")
now={}
for key in sorted(tracked|untracked):
 p=Path(key)
 stat=p.stat()
 now[key]={"kind":"tracked" if key in tracked else "untracked","bytes":stat.st_size,"sha256":sha(p)}
 assert stat.st_size==p.stat().st_size and stat.st_mtime_ns==p.stat().st_mtime_ns,key
assert tracked==paths("--cached") and untracked==paths("--others","--exclude-standard")
delta={k:{"before":before.get(k),"after":now.get(k)} for k in sorted(before.keys()|now.keys()) if before.get(k)!=now.get(k)}
newdocs={"docs/battle-core/pc-campaign-design/"+f for f in ("P02-REPLAY-RESULT-20261108.md","P02-REPLAY-CHECKLIST-20261108.md","SESSION-HANDOFF-P02-REPLAY-20261108.md")}
archive="tmp/P02-REPLAY-DELIVERY-20261108.zip"
p03={k for k in delta if k.startswith("tmp/p03-")}
doc_owned=set(proof)|newdocs
allowed=doc_owned|p03|({archive} if Path(archive).is_file() else set())
checks={"old_paths_present":set(before)<=set(now),"document_only":set(delta)==allowed,
 "document_proof":all(before[p]["sha256"]==data["before_sha256"] and now[p]["sha256"]==data["after_sha256"] and data["reverse_bytes_match"] for p,data in proof.items()),
 "branch":git("symbolic-ref","--short","HEAD").decode().strip()==context["branch"],
 "head":git("rev-parse","HEAD").decode().strip()==context["head"],
 "index_stage":git("ls-files","--stage","-z")== (e/"pre-index.stage.z").read_bytes(),
 "index":sha(os.fsdecode(git("rev-parse","--git-path","index").strip()))==context["index_file_sha256"],
 "class_cache":sha(".godot/global_script_class_cache.cfg")==context["cache_sha256"]}
diff=subprocess.run(("git","diff","--check"),env=env,capture_output=True)
(out/"diff-check.stdout").write_bytes(diff.stdout)
(out/"diff-check.stderr").write_bytes(diff.stderr)
checks["existing_diff_check"]=diff.returncode==context["diff_check_exit"] and diff.stdout==(e/"pre-diff-check.stdout").read_bytes() and diff.stderr==(e/"pre-diff-check.stderr").read_bytes()
checks["added_document_lines_clean"]=all(not line.rstrip(b"\r\n").endswith((b" ",b"\t")) for p in newdocs for line in Path(p).read_bytes().splitlines(keepends=True))
record={"before":len(before),"after":len(now),"checks":checks,"delta":delta,"p03_concurrent":sorted(p03),"user_progress_update":next(p for p in proof if p.endswith("P02-PROGRESS-CHECKLIST.md")),"archive":archive if Path(archive).is_file() else None}
filename="preservation-post-package.json" if Path(archive).is_file() else "preservation.json"
(out/filename).write_text(json.dumps(record,indent=2,ensure_ascii=False)+"\n",encoding="utf8")
print(filename,checks,sorted(delta))
sys.exit(0 if all(checks.values()) else 1)
