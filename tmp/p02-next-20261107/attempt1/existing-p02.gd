extends SceneTree

const Adapter := preload("res://core/battle/operation_runtime_adapter.gd")
const Private := preload("res://core/battle/operation_private_state.gd")
const Cli := preload("res://tests/autoresolve.gd")
const OUT := "res://tmp/p02-next-20261107/attempt1/existing-p02-observations.json"
var checks := 0
var failed := false
var cases: Array = []
var rejected := {}
var natural := 0
var timeout := 0
var policy_cases: Array = []
var timeout_cases: Array = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("P02_ADAPTER_FAIL " + label)

func same(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b): return false
	if a is Dictionary:
		if not same(a.keys(), b.keys()): return false
		for key in a:
			if not same(a[key], b[key]): return false
		return true
	if a is Array:
		if a.get_typed_builtin() != b.get_typed_builtin() or a.size() != b.size(): return false
		for i in a.size():
			if not same(a[i], b[i]): return false
		return true
	return a == b

# Independent enumeration of actual script variables, not capture field lists.
func properties(value: Object, excluded: Array = []) -> Dictionary:
	var out := {}
	for item in value.get_property_list():
		if int(item.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and str(item.name) not in excluded:
			out[item.name] = plain(value.get(item.name))
	return out

func plain(value: Variant) -> Variant:
	if value is Object: return properties(value)
	if value is Dictionary:
		var out := {}
		for key in value: out[key] = plain(value[key])
		return out
	if value is Array:
		var values: Array = []
		for item in value: values.append(plain(item))
		return {"type": value.get_typed_builtin(), "class": str(value.get_typed_class_name()), "script": value.get_typed_script().resource_path if value.get_typed_script() else "", "values": values}
	return value

func oracle(sim: BattleSim) -> Dictionary:
	return {"state": properties(sim.st, ["_idx", "_idx_n"]),
		"sim": properties(sim, ["st", "salvo", "terrain", "detect", "supply", "morale", "victory", "cai", "decisions", "chain", "cmd", "assault", "skills"]),
		"salvo": properties(sim.salvo, ["sim", "C", "terr"]) if sim.salvo else {},
		"terrain": properties(sim.terrain) if sim.terrain else {},
		"detect": properties(sim.detect, ["sim", "D", "terr"]) if sim.detect else {},
		"supply": properties(sim.supply, ["sim", "S"]) if sim.supply else {}}

func input(kind := "poc") -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/p02/" + kind + ".json"))

# Expected fixture ints are explicit independently of the adapter converter.
func raw_profile(kind: String) -> Dictionary:
	var p: Dictionary = input(kind).profile
	p.ally[0].ships = 30 if kind == "poc" else 4
	p.foe[0].ships = 1 if kind == "poc" else 40
	for fleet in p.ally + p.foe:
		fleet.lv = 1
		fleet.p = 0
		if kind == "services":
			fleet.command = 70
			fleet.start_morale_bp = 10000
	if kind == "services":
		p.ally[0].composition[0].count = 1
		p.ally[0].composition[1].count = 1
		p.ally[0].composition[2].count = 2
		p.foe[0].composition[0].count = 40
	return p

func cleanup(sim: BattleSim) -> void:
	for key in ["salvo", "detect", "supply"]:
		var module: Variant = sim.get(key)
		if module: module.sim = null

func close_checked(owner: OperationPrivateState) -> void:
	var held: Array = []
	for key in ["salvo", "detect", "supply"]:
		var module: Variant = owner._sim.get(key)
		if module: held.append(module)
	owner.close()
	for module in held: check(module.sim == null, "close breaks module binding")
	check(owner.read_projection(0).error == "unprepared_owner", "close projection")
	check(owner.summary().error == "unprepared_owner", "close summary")

# Independent policy oracle: constructs exact command dictionaries directly
# from the public DTO, without either production policy implementation.
func reference_commands(policy: String, projection: Dictionary) -> Array:
	var result: Array = []
	if policy != "attack5" or int(projection.tick) % (5 * int(projection.hz)) != 0: return result
	var live_allies: Array = []
	var targetable: Array = []
	for row in projection.squadrons:
		if row.side == 0:
			if not row.dead: live_allies.append(row)
		elif row.has("contact"):
			if row.contact in ["confirmed", "estimated"]: targetable.append(row)
		elif not row.dead: targetable.append(row)
	if live_allies.is_empty(): return result
	var ids: Array = []
	for ally in live_allies:
		ids.append(ally.id)
		var nearest := -1
		var distance := 1e9
		for index in targetable.size():
			var measured: float = (ally.pos as Vector2).distance_to(targetable[index].pos)
			if measured < distance:
				nearest = index
				distance = measured
		if nearest >= 0:
			result.append({"tick": -1, "side": 0, "ids": [ally.id], "kind": "attack", "target_id": targetable[nearest].id, "point": Vector2.ZERO, "args": {}})
	for kind in ["missile", "fighter"]:
		result.append({"tick": -1, "side": 0, "ids": ids.duplicate(), "kind": kind, "target_id": -1, "point": Vector2.ZERO, "args": {}})
	return result

func tuples(commands: Array) -> Array:
	var result: Array = []
	for command in commands:
		check(command.tick == -1 and command.side == 0 and command.point == Vector2.ZERO and command.args.is_empty(), "micro command defaults")
		result.append([command.kind, command.ids, command.target_id])
	return result

func policy_microcases() -> void:
	var ally := {"id": 1, "side": 0, "dead": false, "pos": Vector2.ZERO}
	var dead_ally := {"id": 2, "side": 0, "dead": true, "pos": Vector2.ZERO}
	var full := {"id": 3, "side": 1, "dead": false, "pos": Vector2(10, 0)}
	var full_dead := {"id": 4, "side": 1, "dead": true, "pos": Vector2(1, 0)}
	var confirmed := {"id": 3, "side": 1, "contact": "confirmed", "pos": Vector2(10, 0)}
	var estimated := {"id": 4, "side": 1, "contact": "estimated", "pos": Vector2(20, 0)}
	var lost := {"id": 3, "side": 1, "contact": "lost", "pos": Vector2(1, 0)}
	var tie_first := {"id": 4, "side": 1, "contact": "confirmed", "pos": Vector2(-10, 0)}
	var finish := [["missile", [1], -1], ["fighter", [1], -1]]
	var rows := [
		["P01", "none", 0, [ally, confirmed], []],
		["P02", "attack5", 0, [ally, dead_ally, full, full_dead], [["attack", [1], 3]] + finish],
		["P03", "attack5", 50, [ally, confirmed], [["attack", [1], 3]] + finish],
		["P04", "attack5", 50, [ally, estimated], [["attack", [1], 4]] + finish],
		["P05", "attack5", 50, [ally, lost, estimated], [["attack", [1], 4]] + finish],
		["P06", "attack5", 50, [ally, lost], finish],
		["P07", "attack5", 49, [ally, confirmed], []],
		["P08", "attack5", 50, [ally, tie_first, confirmed], [["attack", [1], 4]] + finish],
		["P09", "attack5", 50, [{"id": 1, "side": 0, "dead": true, "pos": Vector2.ZERO}, confirmed], []]]
	for row in rows:
		var projection := {"tick": row[2], "hz": 10, "squadrons": row[3]}
		var before := var_to_bytes(projection)
		var actual := tuples(Cli._operation_policy_commands(row[1], projection))
		var reference := tuples(reference_commands(row[1], projection))
		check(same(actual, row[4]), row[0] + " production hardcoded oracle")
		check(same(reference, row[4]), row[0] + " reference hardcoded oracle")
		check(var_to_bytes(projection) == before, row[0] + " public DTO preserved")
		policy_cases.append({"id": row[0], "actual": actual, "reference": reference, "expected": row[4]})

func timeout_case(seed_id: int) -> void:
	var data := input("timeout-poc")
	data.seed = seed_id
	var created := Adapter.create(data)
	check(created.ok, "timeout factory")
	if not created.ok: return
	var owner: OperationPrivateState = created.owner
	var profile: Dictionary = data.profile.duplicate(true)
	for fleet in profile.ally + profile.foe:
		fleet.ships = 30
		fleet.lv = 1
		fleet.p = 0
	var raw := BattleSim.new(seed_id, 10, profile)
	for fleet in raw.st.fleets: fleet.control = "direct"
	raw.projection(0)
	check(not raw.st.over and raw.st.tick == 0 and raw.st.clock_ms == 0 and raw.st.alive(0).size() == 1 and raw.st.alive(1).size() == 1, "timeout raw initial survival")
	check(same(oracle(owner._sim), oracle(raw)), "timeout initial full oracle")
	var run := Cli.run_operation(owner, "none", 1)
	raw.step()
	# Match the consumer's aggregation container without weakening exact equality.
	# drain_events itself is typed Array[Dictionary]; the run DTO accumulates into
	# an untyped Array, even for one step and even when there are no events.
	var expected_events: Array = []
	expected_events.append_array(raw.drain_events())
	check(run.ok and same(run.events, expected_events) and same(oracle(owner._sim), oracle(raw)), "timeout raw one step")
	var summary: Dictionary = run.summary
	check(summary.tick == 1 and summary.clock_ms == 100 and not summary.over and summary.reason == "timeout" and summary.end_tick == -1 and summary.end_ms == -1 and summary.commands == 0, "timeout exact DTO")
	check(raw.st.alive(0).size() == 1 and raw.st.alive(1).size() == 1, "timeout raw afterstep survival")
	timeout_cases.append({"id": "T01" if seed_id == 0 else "T02", "seed": seed_id, "summary": summary, "event_count": run.events.size()})
	close_checked(owner)
	cleanup(raw)

func normal(seed_id: int, kind: String, policy: String) -> void:
	var data := input(kind)
	data.seed = seed_id
	data.policy = policy
	var before := var_to_bytes(data)
	var made := Adapter.create(data)
	check(made.ok, "factory " + kind)
	if not made.ok: return
	check(not made.meta.has("profile") and not made.has("value"), "factory metadata no profile")
	var owner: OperationPrivateState = made.owner
	var raw := BattleSim.new(seed_id, 10, raw_profile(kind))
	for i in 2: raw.st.fleets[i].control = ["direct", "delegate"][i]
	raw.projection(0) # Same documented initial public observation, not capture.
	check(same(oracle(owner._sim), oracle(raw)), "initial full independent state")
	check(owner.summary().summary.tick == 0 and owner.summary().summary.clock_ms == 0 and owner._sim._queue.is_empty(), "C0 clock queue")
	var events: Array = []
	var expected_events: Array = []
	var intermediate := []
	while not raw.st.over and raw.st.tick < 1200:
		var projected := owner.read_projection(0)
		var public_raw := raw.projection(0)
		check(projected.ok and same(projected.projection, public_raw), "public projection")
		if raw.st.tick in [5, 10, 15]:
			var before_read := oracle(owner._sim)
			var summary := owner.summary()
			summary.summary.tick = -99
			projected.projection.squadrons[0].name = "mutated"
			check(same(before_read, oracle(owner._sim)), "read aliases detached/no queue or event consumption")
			check(owner.read_projection(0).projection.squadrons[0].name != "mutated" and owner.summary().summary.tick == raw.st.tick, "read alias future reads")
			intermediate.append(owner.summary().summary)
		if raw.st.tick == 1:
			var immediate := BattleSim.command(0, [1], "stop")
			check(owner.issue(immediate).ok, "immediate issue")
			raw.issue(immediate.duplicate(true))
			check(same(oracle(owner._sim), oracle(raw)), "issue immediate oracle")
			var before_reject := oracle(owner._sim)
			check(owner.issue(BattleSim.command(0, [1], "charge")).error == "unsupported_command", "unsupported issue")
			check(same(before_reject, oracle(owner._sim)), "failed command atomic")
			var pending := BattleSim.command(0, [1], "attack", 2)
			check(owner.queue(pending).ok, "pending queue")
			raw.queue(pending.duplicate(true))
			check(owner._sim.st.tick == 1 and owner._sim._queue.size() == 1, "queue before next step")
		for command in Cli._operation_policy_commands(policy, owner.read_projection(0).projection):
			check(owner.queue(command).ok, "policy queue")
		for command in reference_commands(policy, public_raw): raw.queue(command)
		check(same(oracle(owner._sim), oracle(raw)), "prestep ordered queue")
		check(owner.advance().ok, "advance")
		raw.step()
		check(same(oracle(owner._sim), oracle(raw)), "poststep full independent state")
		var drained := owner.drain_events()
		var expected := raw.drain_events()
		check(drained.ok and same(drained.events, expected), "ordered events")
		events.append_array(drained.events)
		expected_events.append_array(expected)
		check(owner.drain_events().events.is_empty(), "event consumed once")
	var summary: Dictionary = owner.summary().summary
	check(summary.tick == raw.st.tick and summary.clock_ms == raw.st.clock_ms and summary.fp == raw.fingerprint(), "clock summary fingerprint")
	check(summary.commands == raw.command_log.size() and same(events, expected_events), "command count ordered events")
	check(not events.is_empty(), "actual event generation")
	if raw.st.over: natural += 1
	else: timeout += 1
	check(var_to_bytes(data) == before, "input unchanged")
	# The actual consumer is compared to raw commands produced independently.
	var twin: Dictionary = Adapter.create(data)
	check(twin.ok, "fresh twin")
	var twin_raw := BattleSim.new(seed_id, 10, raw_profile(kind))
	for i in 2: twin_raw.st.fleets[i].control = ["direct", "delegate"][i]
	twin_raw.projection(0)
	var run := Cli.run_operation(twin.owner, policy, 1200)
	var twin_events: Array = []
	while not twin_raw.st.over and twin_raw.st.tick < 1200:
		for command in reference_commands(policy, twin_raw.projection(0)): twin_raw.queue(command)
		twin_raw.step()
		twin_events.append_array(twin_raw.drain_events())
	check(run.ok and same(run.events, twin_events), "actual consumer helper ordered events")
	check(same(oracle(twin.owner._sim), oracle(twin_raw)), "actual consumer independent full state")
	cases.append({"seed": seed_id, "profile": kind, "policy": policy, "summary": summary, "consumer_summary": run.summary, "event_count": events.size(), "checkpoints": intermediate})
	close_checked(owner)
	close_checked(twin.owner)
	cleanup(raw)
	cleanup(twin_raw)

func reject(id: String, data: Variant, code: String, path: String) -> void:
	var before := var_to_bytes(data)
	var result := Adapter.create(data)
	check(not result.ok and result.error == code and result.path == path and not result.has("owner"), id + " error/path/no owner " + str(result))
	check(var_to_bytes(data) == before, id + " input preserved")
	rejected[id] = {"error": result.get("error"), "path": result.get("path")}

func negatives() -> void:
	var data := input()
	data.erase("profile"); reject("N02", data, "missing_field", "profile")
	for row in [["N04", "mode", "other", "unsupported_mode"], ["N05", "format", "other", "unsupported_input_representation"], ["N06", "extra", 1, "unsupported_field"], ["N07", "seed", 0.5, "invalid_integer"], ["N09", "hz", 20, "unsupported_hz"], ["N10", "initial_controls", ["direct"], "initial_controls"]]:
		data = input(); data[row[1]] = row[2]; reject(row[0], data, row[3], row[1])
	data = input(); data.profile.ally[0].ships = 1.5; reject("N08", data, "invalid_integer", "profile.ally[0].ships")
	data = input(); data.initial_controls[0] = "other"; reject("N11", data, "initial_controls", "initial_controls[0]")
	data = input(); data.profile.reinf = [{}]; reject("N12", data, "unsupported_reinforcement", "profile.reinf")
	data = input("services"); data.profile.combat.morale = {}; reject("N13", data, "unsupported_module_config", "profile.combat")
	data = input(); data.definition = {}; reject("N16", data, "unsupported_input_representation", "definition")
	data = input(); data.checkpoint = {}; reject("N17", data, "unsupported_checkpoint", "checkpoint")
	data = input(); data.profile.extra = 1; reject("N18", data, "unsupported_profile_field", "profile")
	reject("X01", [], "invalid_container", "$")
	data = input(); data.profile.ally = 5; reject("X02", data, "invalid_container", "profile.ally")
	data = input(); data.profile.ally[0] = 5; reject("X03", data, "invalid_container", "profile.ally[0]")
	data = input(); data.profile.ally[0].composition = 5; reject("X04", data, "invalid_container", "profile.ally[0].composition")
	data = input(); data.profile.ally[0].composition = [5]; reject("X05", data, "invalid_container", "profile.ally[0].composition[0]")
	for row in [["X06", "seed", 1e30], ["X07", "max_ticks", 1e30], ["X11", "seed", true], ["X12", "max_ticks", INF]]:
		data = input(); data[row[1]] = row[2]; reject(row[0], data, "invalid_integer", row[1])
	data = input(); data.profile.ally[0].ships = 1e30; reject("X08", data, "invalid_integer", "profile.ally[0].ships")
	data = input(); data.profile.ally[0].composition = [{"count": 1e30}]; reject("X09", data, "invalid_integer", "profile.ally[0].composition[0].count")
	data = input(); data.profile.ally[0].composition = [{"count": 2147483647}, {"count": 1}]; reject("X10", data, "integer_total_overflow", "profile.ally[0].composition")
	var created := Adapter.create(input("services"))
	check(created.ok, "negative read owner")
	if not created.ok: return
	var owner: OperationPrivateState = created.owner
	for row in [["Y01", 0.0], ["Y02", 2]]:
		var before := oracle(owner._sim)
		var result := owner.read_projection(row[1])
		check(not result.ok and result.error == "invalid_side" and result.path == "side", row[0])
		check(same(before, oracle(owner._sim)) and owner.read_projection(0).ok, "invalid side nonmutation/recovery")
		rejected[row[0]] = {"error": result.error, "path": result.path}
	owner._busy = true
	for row in [["Y03", "read_projection"], ["Y05", "summary"]]:
		var result: Dictionary = owner.read_projection(0) if row[1] == "read_projection" else owner.summary()
		check(not result.ok and result.error == "busy" and result.path == "owner", row[0])
		rejected[row[0]] = {"error": result.error, "path": result.path}
	owner._busy = false
	check(owner.issue(BattleSim.command(0, [1], "stop")).ok, "normal issue after read failure")
	close_checked(owner)
	for row in [["Y04", "read_projection"], ["Y06", "summary"]]:
		var result: Dictionary = owner.read_projection(0) if row[1] == "read_projection" else owner.summary()
		check(not result.ok and result.error == "unprepared_owner" and result.path == "owner", row[0])
		rejected[row[0]] = {"error": result.error, "path": result.path}
	# Technical maxima are tested purely; no enormous simulation is allocated.
	data = input(); data.seed = 4294967295.0; data.max_ticks = 2147483647.0
	data.profile.ally[0].ships = 2147483647.0
	data.profile.ally[0].composition = [{"count": 2147483647.0}]
	var pure := Adapter.normalize(data)
	check(pure.ok, "pure maximum")
	if pure.ok:
		check(typeof(pure.value.seed) == TYPE_INT and pure.value.seed == 4294967295, "seed maximum int")
		check(typeof(pure.value.max_ticks) == TYPE_INT and pure.value.max_ticks == 2147483647, "tick maximum int")
		check(typeof(pure.value.profile.ally[0].ships) == TYPE_INT and pure.value.profile.ally[0].ships == 2147483647 and pure.value.profile.ally[0].composition[0].count == 2147483647, "fleet/count maximum int")
		pure.value.profile.ally[0].name = "changed"
		check(data.profile.ally[0].name == "A", "pure result detached")
	# Existing active runtime survives factory failure; caller ownership is separate.
	created = Adapter.create(input())
	var before := oracle(created.owner._sim)
	data = input(); data.profile.reinf = [{}]
	check(not Adapter.create(data).ok and same(before, oracle(created.owner._sim)), "factory failure preserves existing owner")
	close_checked(created.owner)

func _run() -> void:
	check(Private._classes() == "", "canonical runtime paths")
	if Private._classes() != "": quit(1); return
	policy_microcases()
	for seed_id in [0, 7]: timeout_case(seed_id)
	for seed_id in [0, 7]:
		for kind in ["poc", "services"]:
			for policy in ["none", "attack5"]: normal(seed_id, kind, policy)
	negatives()
	check(cases.size() == 8 and rejected.size() == 32, "exact API denominator")
	check(policy_cases.size() == 9 and timeout_cases.size() == 2, "exact supplemental denominator")
	check(natural > 0, "natural end exercised")
	var result := {"ok": not failed, "checks": checks, "cases": cases, "rejections": rejected, "policy_microcases": policy_cases, "timeout_cases": timeout_cases, "natural": natural, "timeout": timeout, "class_guard": Private._classes()}
	var output := FileAccess.open(OUT, FileAccess.WRITE)
	output.store_string(JSON.stringify(result, "\t"))
	output.close()
	print("P02_ADAPTER_%s cases=%d checks=%d rejections=%d natural=%d timeout=%d" % ["FAIL" if failed else "PASS", cases.size(), checks, rejected.size(), natural, timeout])
	quit(1 if failed else 0)
