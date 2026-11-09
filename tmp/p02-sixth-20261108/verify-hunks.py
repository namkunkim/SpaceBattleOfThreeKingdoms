from pathlib import Path
import difflib, hashlib, json, re
D=Path("tmp/p02-sixth-20261108")
ALLOWED={
 "scripts/FleetBattle3D.gd":{"_ready","init_game","_prepare_game","_publish_game","_restart"},
 "hud/ui_kit/command_deck.gd":{"begin_battle","restart","to_title"},
 "hud/ui_kit/org_screen.gd":{"_load","_apply_load","start_auto","open_org"}
}
def function_map(raw):
 lines=raw.splitlines(keepends=True)
 active=""
 names=[]
 for line in lines:
  function=re.match(rb"(?:static )?func (\w+)\(",line)
  if function: active=function[1].decode()
  elif line and not line.startswith((b"\t",b"\n",b"\r",b"#")): active=""
  names.append(active)
 return lines,names
report={}
for name,allowed in ALLOWED.items():
 path=Path(name)
 before=(D/(path.name+".before.txt")).read_bytes()
 after=path.read_bytes()
 old,old_functions=function_map(before)
 new,new_functions=function_map(after)
 changed=[]
 reversed_lines=[]
 for tag,a,b,c,d in difflib.SequenceMatcher(a=old,b=new,autojunk=False).get_opcodes():
  if tag=="equal":
   reversed_lines.extend(new[c:d])
   continue
  def names(lines,functions,start,end):
   return {functions[i] for i in range(start,end) if lines[i].strip()}
  scope=names(old,old_functions,a,b)|names(new,new_functions,c,d)
  assert scope<=allowed,(name,scope-allowed)
  reversed_lines.extend(old[a:b])
  changed.append({"before":[a+1,b],"after":[c+1,d],"functions":sorted(scope)})
 assert b"".join(reversed_lines)==before
 report[name]={"before_sha256":hashlib.sha256(before).hexdigest(),"after_sha256":hashlib.sha256(after).hexdigest(),"changed":changed,"reverse_byte_match":True}
(D/"product-hunk-proof.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf8")
