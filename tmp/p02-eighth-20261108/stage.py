from pathlib import Path
import hashlib, json, os, shutil, subprocess
from concurrent.futures import ThreadPoolExecutor
R=Path.cwd()
D=Path(__file__).resolve().parent
T=D/'candidate-k1'
E=Path('C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe')
F='scripts/FleetBattle3D.gd'
A='scripts/world/auto_resolver.gd'
O='core/battle/operation_runtime_adapter.gd'
def sha(p):
 with open(p,'rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def scan(r, paths):
 with ThreadPoolExecutor(8) as pool:return dict(zip(paths,pool.map(lambda n:sha(r/n),paths)))
def dump(p,x):p.write_text(json.dumps(x,ensure_ascii=False,indent=2),encoding='utf-8')
def repl(p,old,new):
 b=p.read_bytes()
 nl='\r\n' if b'\r\n' in b else '\n'
 old,new=[s.replace('\n',nl).encode() for s in (old,new)]
 assert b.count(old)==1,p
 p.write_bytes(b.replace(old,new))
def edit(after):
 repl(after/O,'static func _integer','''# Legacy product callers supply their effective profile by reference.
# They still own profile preparation, publication, and worker startup.
static func create_product_native(profile: Dictionary, seed: int, mode: String) -> Dictionary:
	if mode != "direct" and mode != "auto":
		return fail("unsupported_mode", "mode")
	var sim := BattleSim.new(seed, BattleRules.TICK_HZ, profile)
	if mode == "auto":
		sim.set_manual_all(false)
	else:
		for f in sim.st.fleets:
			if f.side == 0 and f.faction == "liu_bei":
				f.control = "direct"
	return {"ok": true, "sim": sim}

static func _integer''')
 repl(after/F,'''	var candidate_sim := BattleSim.new(candidate_seed, BattleRules.TICK_HZ, profile)
	# 플레이어 유비군은 처음부터 직접 지휘한다. 손권군·적군은 기존 위임 AI를 쓴다.
	for f in candidate_sim.st.fleets:
		if f.side == 0 and f.faction == "liu_bei":
			f.control = "direct"
	return {"ok": true, "seed": candidate_seed, "sim": candidate_sim,''','''	var native := preload("res://core/battle/operation_runtime_adapter.gd").create_product_native(profile, candidate_seed, "direct")
	if not native.ok:
		return native
	return {"ok": true, "seed": candidate_seed, "sim": native.sim,''')
 repl(after/A,'''	sim = BattleSim.new(brief.seed, BattleRules.TICK_HZ, p)
	sim.set_manual_all(false)''','''	var native := OperationAdapter.create_product_native(p, brief.seed, "auto")
	if not native.ok:
		error = "%s at %s" % [native.error, native.path]
		return false
	sim = native.sim''')
def main():
 T.mkdir()
 previous=json.loads((R/'tmp/p02-seventh-20261108/after-attempt-02/inputs.json').read_bytes())
 paths=set(n for n in previous if not n.startswith('tmp/'))
 for folder in ('core','scripts','scenes','data','view','hud','input','tests'):
  paths.update(p.relative_to(R).as_posix() for p in (R/folder).rglob('*') if p.is_file())
 paths=sorted(paths|{O})
 now=scan(R,paths)
 dump(T/'source.json',now)
 dump(T/'engine.json',{str(e):sha(e) for e in (E,E.with_name(E.name.replace('_console','')))})
 for stage in ('before','after'):
  dst=T/stage
  for n in paths:
   f=dst/n
   f.parent.mkdir(parents=True,exist_ok=True)
   shutil.copyfile(R/n,f)
  assert scan(dst,paths)==now
 assert scan(R,paths)==now
 edit(T/'after')
 after=scan(T/'after',paths)
 assert {n for n in paths if now[n]!=after[n]}=={F,A,O}
 dump(T/'after.json',after)
 print('Frozen source paths:',len(paths))
if __name__=='__main__':main()
