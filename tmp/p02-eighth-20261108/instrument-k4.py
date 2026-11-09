from stage import *
from itertools import chain
S=T/'after'
I=T/'instrumented-k4'
I.mkdir()
expected=json.loads((T/'after.json').read_bytes())
for n in expected:
 dest=I/n
 dest.parent.mkdir(parents=True,exist_ok=True)
 if n in (F,A,O) or n.startswith('.godot/'):
  shutil.copyfile(S/n,dest)
 else:
  shutil.copyfile(S/n,dest)
assert scan(I,expected)==expected
repl(I/O,'static func create_product_native','''static var probe_enter: int = 0
static var probe_ctor: int = 0
static var probe_publish: int = 0
static var probe_thread: int = 0
static var probe_mode: String = ""
static var probe_profile: Dictionary = {}
static var probe_seed: int = 0
static var probe_error: Dictionary = {}

static func create_product_native''')
repl(I/O,'''	if mode != "direct" and mode != "auto":
		return fail("unsupported_mode", "mode")
	var sim := BattleSim.new(seed, BattleRules.TICK_HZ, profile)''','''	probe_enter += 1
	probe_profile = profile
	probe_seed = seed
	if mode != "direct" and mode != "auto":
		probe_error = fail("unsupported_mode", "mode")
		return probe_error
	probe_ctor += 1
	var sim := BattleSim.new(seed, BattleRules.TICK_HZ, profile)''')
repl(I/F,'create_product_native(profile, candidate_seed, "direct")','create_product_native(profile, candidate_seed, "direct" if OS.get_environment("P02_PROBE_MODE") != "direct" else "invalid")')
repl(I/A,'create_product_native(p, brief.seed, "auto")','create_product_native(p, brief.seed, "auto" if OS.get_environment("P02_PROBE_MODE") != "auto" else "invalid")')
repl(I/F,'func _publish_game(candidate: Dictionary, candidate_org: Dictionary) -> void:', '''func _publish_game(candidate: Dictionary, candidate_org: Dictionary) -> void:
	preload("res://core/battle/operation_runtime_adapter.gd").probe_publish += 1''')
repl(I/A,'	_thread.start(_run_legacy)','''	OperationAdapter.probe_thread += 1
	_thread.start(_run_legacy)''')
now=scan(I,expected)
assert {n for n,h in expected.items() if now[n]!=h}=={F,A,O}
assert scan(S,expected)==expected
dump(T/'instrumented-k4.json',now)

