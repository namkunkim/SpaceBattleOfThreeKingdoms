from pathlib import Path

p = Path(__file__).resolve().parent
def load(name):
    return (p / name).read_text(encoding="utf-8-sig")
def save(name, text):
    with (p / name).open("x", encoding="utf-8") as f:
        f.write(text)

s = load("overlays_v2.py").replace('tests/test_check.gd','tests/lib/check.gd').replace('condition: bool, message: String) -> bool:', 'cond: bool, msg: String = "") -> bool:').replace('[message, condition]', '[msg, cond]')
# Match the default-string source declaration without changing runtime behavior.
s = s.replace('    return changes', '''    if case == "autoresolve":
        old = '\\t\\t\\tif not cmp.pass:'
        edit("tests/autoresolve.gd", old, '\\t\\t\\tprint("K6_SUITE_ASSERT ", JSON.stringify([pol, cmp.pass]))\\n' + old)
        old = '\\tif not ok:'
        edit("tests/autoresolve.gd", old, '\\tprint("K6_SUITE_ASSERT ", JSON.stringify(["legacy-overall", ok]))\\n' + old)
    return changes''')
(p / "overlays_v2.py").write_text(s, encoding="utf-8")
s = load("deployment.gd")
s = s.replace('var s := f.presentation.hud', 'var s: Node = f.presentation.hud')
s = s.replace('var projected_events: Array = []', 'var projected_events: Array[Dictionary] = []')
s = s.replace('projected_events.append(n.drain_events_for(0))','projected_events.append_array(n.drain_events_for(0))')
s = s.replace('var actual: BattleSim = f.sim','f.k6_events.clear()\n\tvar actual: BattleSim = f.sim')
s = s.replace('observe("viewer-native", projected_events)','observe("viewer-native", projected_events)\n\tobserve("viewer-product", f.k6_events)\n\tcheck("typed-viewer-events", var_to_bytes(f.k6_events) == var_to_bytes(projected_events))')
save("deployment_v2.gd",s)
s = load("rejection.gd")
s = s.replace('"commands":s.command_log.duplicate(true), "trace_seq"', '"commands":s.command_log.duplicate(true), "next_event_id":s.st.next_event_id,\n\t\t"accumulator":[f.clock.hz, f.clock.speed, f.clock.acc, f.clock.dropped], "trace_seq"')
s = s.replace('func subsequent(f: Node) -> Array:\n', 'func subsequent(f: Node) -> Array:\n\tf.k6_events.clear()\n')
s = s.replace('f.sim.projection(0)]', 'f.sim.projection(0), f.k6_events.duplicate(true)]')
s = s.replace('func factory_contract() -> void:\n', 'func factory_contract() -> void:\n\tvar instrumented := args[0] == "instrumented"\n')
s = s.replace('\t\t\treset()\n\t\t\tvar value:', '\t\t\tif instrumented:\n\t\t\t\treset()\n\t\t\tvar value:')
s = s.replace('s.fingerprint(), counters()])','s.fingerprint()])')
s = s.replace('\t\t\tcheck("calls/" + id, counters() == [1,1,0,0])','\t\t\tif instrumented:\n\t\t\t\tsave("counts/" + id, counters())\n\t\t\t\tcheck("calls/" + id, counters() == [1,1,0,0])')
s = s.replace('for mode in ["invalid", ""]:\n\t\treset()', 'for mode in ["invalid", ""]:\n\t\tif instrumented:\n\t\t\treset()')
s = s.replace('save("reject/" + mode, [fail, counters()])','save("reject/" + mode, fail)\n\t\tif instrumented:\n\t\t\tsave("reject-counts/" + mode, counters())')
s = s.replace('and counters() == [1,0,0,0])','and (not instrumented or counters() == [1,0,0,0]))')
save("rejection_v2.gd",s)
s = load("native.gd")
s = s.replace('''		f.profile_def = ""
		f.profile_patch = Callable()
		var poc: Dictionary = f._prepare_game({})
		compare("poc", poc.sim, native(PocSetup.profile(), SEED, "direct"))''','''		var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
		battle.profile_def = ""
		root.add_child(battle)
		battle.set_process(false)
		var prior: BattleSim = battle.sim
		var init: Dictionary = battle.init_game()
		check("poc/published", init.ok and battle.sim != null and battle.sim != prior and battle.battle_seed == SEED and battle.sim.st.hz == 10)
		record("poc/effective", PocSetup.profile())
		var expected := native(PocSetup.profile(), SEED, "direct")
		expected.drain_events()
		compare("poc", battle.sim, expected)
		battle.free()''')
save("native_v2.gd",s)
