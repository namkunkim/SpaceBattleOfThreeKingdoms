from pathlib import Path
p = Path(__file__).with_name("native.gd")
s = p.read_text(encoding="utf-8-sig")
s = s.replace("var report: FileAccess","var report: FileAccess\nvar diff_filter := args[2]")
s = s.replace("for diff in BattleBrief.difficulties():","for diff in BattleBrief.difficulties():\n\t\tif diff != diff_filter:\n\t\t\tcontinue")
s = s.replace('var a := AutoResolver.new(b)', 'b.mode = "auto"\n\t\tvar a := AutoResolver.new(b)')
s = s.replace('compare(diff + "/auto", a.sim, native(source(diff), SEED, "auto"))', '''record(diff + "/auto-effective", a.get("k6_effective"))
		check(diff + "/auto-effective", var_to_bytes(a.get("k6_effective")) == var_to_bytes(source(diff)))
		compare(diff + "/auto", a.sim, native(source(diff), SEED, "auto"))
		f.profile_patch = Callable()
		var direct_view: Dictionary = f._prepare_game({})
		compare_view(diff + "/direct", direct_view.sim, native(direct_effective(diff), SEED, "direct"))
		var auto_view := AutoResolver.new(b)
		check(diff + "/auto-view-prepare", auto_view._prepare())
		compare_view(diff + "/auto", auto_view.sim, native(source(diff), SEED, "auto"))
		var direct_reinf: Dictionary = f._prepare_game({})
		compare_reinf(diff + "/direct", direct_reinf.sim, native(direct_effective(diff), SEED, "direct"))
		var auto_reinf := AutoResolver.new(b)
		check(diff + "/auto-reinf-prepare", auto_reinf._prepare())
		compare_reinf(diff + "/auto", auto_reinf.sim, native(source(diff), SEED, "auto"))''')
s = s.replace('f.profile_def = ""', 'if diff_filter == "poc":\n\t\tf.profile_def = ""').replace('\n\tf.profile_patch = Callable()\n\tvar poc:', '\n\t\tf.profile_patch = Callable()\n\t\tvar poc:').replace('\n\tcompare("poc"', '\n\t\tcompare("poc"')
start = s.index('\n\tf.profile_def = BattleBrief.PROFILE_DEF')
s = s[:start] + '''
	f.free()
	if diff_filter == "invalid-brief":
		b.difficulty = "unknown-difficulty"
		var invalid := AutoResolver.new(b)
		var started := invalid.start()
		record("legacy-invalid-brief", [b.to_dict(), started, invalid.error, invalid._thread == null, invalid.outcome == null])
		check("legacy-invalid-brief", not started and invalid.error == "알 수 없는 난이도: unknown-difficulty" and invalid._thread == null and invalid.outcome == null)
	report.close()
	quit(0 if fail_count == 0 else 1)
'''
extra = '''
func step_to(s: BattleSim, tick: int) -> void:
	while s.st.tick < tick and not s.st.over:
		s.step()

func compare_view(label: String, actual: BattleSim, oracle: BattleSim) -> void:
	for tick in [0, 1, 10, 100]:
		step_to(actual, tick)
		step_to(oracle, tick)
		var a := [actual.st.tick, actual.projection(0), actual.drain_events_for(0)]
		var b := [oracle.st.tick, oracle.projection(0), oracle.drain_events_for(0)]
		record(label + "/viewer/actual/" + str(tick), a)
		record(label + "/viewer/native/" + str(tick), b)
		check(label + "/viewer/" + str(tick), actual.st.tick == tick and var_to_bytes(a) == var_to_bytes(b))

func compare_reinf(label: String, actual: BattleSim, oracle: BattleSim) -> void:
	var prior := {}
	var oracle_prior := {}
	while not actual.st.reinf and not oracle.st.reinf and not actual.st.over and not oracle.st.over and actual.st.tick < 18000:
		prior = snapshot(actual)
		oracle_prior = snapshot(oracle)
		actual.step()
		oracle.step()
	var natural := [actual.st.reinf, oracle.st.reinf]
	record(label + "/reinf/natural", natural)
	check(label + "/reinf-before", var_to_bytes(prior) == var_to_bytes(oracle_prior))
	record(label + "/reinf/prior", [prior, oracle_prior])
	if natural == [false, false]:
		record(label + "/reinf/source", "DEBUG_FORCED_AFTER_NATURAL_UNOBSERVED")
		actual.debug_spawn_reinf()
		oracle.debug_spawn_reinf()
	var a := snapshot(actual)
	var b := snapshot(oracle)
	record(label + "/reinf/first", [a,b])
	check(label + "/reinf-first", natural[0] == natural[1] and actual.st.reinf and oracle.st.reinf and var_to_bytes(a) == var_to_bytes(b))

'''
s = s.replace("func _run() -> void:", extra + "func _run() -> void:")
p.write_text(s,encoding="utf-8")
