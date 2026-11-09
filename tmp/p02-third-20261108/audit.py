from pathlib import Path
import hashlib,json,os,subprocess,sys
e=Path("tmp/p02-third-20261108")
base=json.loads((e/"pre-baseline-files.json").read_text(encoding="utf8"))
context=json.loads((e/"pre-baseline-context.json").read_text(encoding="utf8"))
env=dict(os.environ,GIT_OPTIONAL_LOCKS="0")
def git(*args):
 r=subprocess.run(("git",*args),env=env,capture_output=True)
 assert not r.returncode,(args,r.stderr)
 return r.stdout
def sha(p):
 with Path(p).open("rb") as f: return hashlib.file_digest(f,"sha256").hexdigest()
def listing(*args):
 return {s.decode("utf8") for s in git("ls-files","-z",*args).split(b"\0") if s and not s.startswith(b"tmp/p02-third-20261108/")}
tracked=listing("--cached")
untracked=listing("--others","--exclude-standard")
now={}
for path in sorted(tracked|untracked):
 p=Path(path)
 row={"kind":"tracked" if path in tracked else "untracked"}
 if p.is_file():
  before=p.stat()
  row.update(bytes=before.st_size,sha256=sha(p))
  after=p.stat()
  assert before.st_size==after.st_size and before.st_mtime_ns==after.st_mtime_ns,path
 else: row.update(missing=True)
 now[path]=row
assert tracked==listing("--cached") and untracked==listing("--others","--exclude-standard")
delta={k:{"before":base.get(k),"after":now.get(k)} for k in sorted(base.keys()|now.keys()) if base.get(k)!=now.get(k)}
owned={"tests/autoresolve.gd","core/battle/operation_replay.gd","tests/p02_replay_adapter.gd","tests/fixtures/p02/replay-commands.json","tests/fixtures/p02/replay-natural.json","tests/fixtures/p02/replay-one-tick.json"}
p03={name for name in delta if name.startswith("tmp/p03-")}
user={name for name in delta if name=="docs/battle-core/pc-campaign-design/P02-PROGRESS-CHECKLIST.md"}
unknown=set(delta)-owned-p03-user
def reverse_cli():
 old=(e/"autoresolve.before.txt").read_bytes()
 new=Path("tests/autoresolve.gd").read_bytes()
 nl=b"\r\n" if b"\r\n" in old else b"\n"
 replay=(e/"replay-cli.gd.txt").read_text(encoding="utf-8-sig").rstrip()+"\n\n"
 lines=["\tif \"--operation-replay\" in OS.get_cmdline_user_args():\n\t\t_run_operation_replay_cli()\n\t\treturn\n","\tif \"--operation-replay\" in args and (\"--operation-input\" in args or \"--operation-worker\" in args):\n\t\treturn adapter.fail(\"conflicting_option\", \"--operation-replay\")\n",replay]
 for piece in lines:
  b=piece.encode().replace(b"\n",nl)
  assert new.count(b)==1
  new=new.replace(b,b"",1)
 return old==new
diff=subprocess.run(("git","diff","--check"),capture_output=True,env=env)
(e/"post-diff-check.stdout").write_bytes(diff.stdout)
(e/"post-diff-check.stderr").write_bytes(diff.stderr)
same_diff=diff.returncode==context["diff_check_exit"] and diff.stdout==(e/"pre-diff-check.stdout").read_bytes() and diff.stderr==(e/"pre-diff-check.stderr").read_bytes()
checks={
 "branch":git("symbolic-ref","--short","HEAD").decode().strip()==context["branch"],
 "head":git("rev-parse","HEAD").decode().strip()==context["head"],
 "index_stage":git("ls-files","--stage","-z")== (e/"pre-index.stage.z").read_bytes(),
 "index":sha(os.fsdecode(git("rev-parse","--git-path","index").strip()))==context["index_file_sha256"],
 "class_cache":sha(".godot/global_script_class_cache.cfg")==context["cache_sha256"],
 "diff_check_before_after":same_diff,
 "own_hunks_only":reverse_cli(),
 "owned_expected":owned <= set(delta),
 "all_old_paths_present":set(base) <= set(now),
 "unknown_changes_empty":not unknown,
}
(e/"post-baseline-files.json").write_text(json.dumps(now,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
(e/"preservation.json").write_text(json.dumps({"baseline":len(base),"final":len(now),"checks":checks,"owned":sorted(owned),"p03":sorted(p03),"user":sorted(user),"unknown":sorted(unknown),"delta":delta},ensure_ascii=False,indent=2)+"\n",encoding="utf8")
print(len(base),len(now),checks,sorted(unknown),sorted(p03),sorted(user))
sys.exit(0 if all(checks.values()) else 1)
