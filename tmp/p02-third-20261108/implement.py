from pathlib import Path
import shutil
root=Path("tmp/p02-third-20261108")
dest=Path("tests/autoresolve.gd")
before=(root/"autoresolve.before.txt").read_bytes()
assert dest.read_bytes()==before
newline=b"\r\n" if b"\r\n" in before else b"\n"
def lines(text): return text.encode().replace(b"\n",newline)
def read_text(name): return (root/name).read_text(encoding="utf-8-sig")
added={}
def insert(marker, addition):
 global before
 assert before.count(lines(marker))==1
 before=before.replace(lines(marker),lines(addition+marker),1)
 added[marker]=addition
insert('\tif "--operation-worker" in OS.get_cmdline_user_args():\n','\tif "--operation-replay" in OS.get_cmdline_user_args():\n\t\t_run_operation_replay_cli()\n\t\treturn\n')
insert('\tif "--operation-input" in args and "--operation-worker" in args:\n','\tif "--operation-replay" in args and ("--operation-input" in args or "--operation-worker" in args):\n\t\treturn adapter.fail("conflicting_option", "--operation-replay")\n')
insert('func _write_operation_result(result: Dictionary, out_path: String) -> void:\n',read_text("replay-cli.gd.txt").rstrip()+"\n\n")
dest.write_bytes(before)
assert all(before.count(lines(addition+marker))==1 for marker,addition in added.items())
for marker,addition in added.items():
 before=before.replace(lines(addition+marker),lines(marker),1)
assert before==(root/"autoresolve.before.txt").read_bytes()
for source,target in [("operation_replay.gd.txt","core/battle/operation_replay.gd"),("p02_replay_adapter.gd.txt","tests/p02_replay_adapter.gd")]:
 Path(target).write_text(read_text(source),encoding="utf8",newline="\n")
for name in ("commands","one-tick","natural"):
 shutil.copyfile(root/"matrix"/(name+".json"),Path("tests/fixtures/p02")/("replay-"+name+".json"))
