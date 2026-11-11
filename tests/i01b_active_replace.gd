extends SceneTree

const Private := preload("res://core/battle/operation_private_state.gd")
const SEEDS := [0, 1, 20824, 20825, 20826, 90210, 123456789, 2147483647, 2147483648, 4294967295]
const OUT := "res://tmp/i01b-active-replace-20261102/attempt2-observations.json"
var checks := 0
var failed := false
var cases: Array = []
var rejections := {}
var refusal_calls := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("I01B_ACTIVE_REPLACE_FAIL " + label)

func _same(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b): return false
	if a is Dictionary:
		if not _same(a.keys(), b.keys()): return false
		for key in a:
			if not _same(a[key], b[key]): return false
		return true
	if a is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not _same(a[i], b[i]): return false
		return true
	return a == b

# Independent observations enumerate actual script properties, not the codec's
# field lists. Container metadata is recorded before any JSON diagnostics.
func _properties(value: Object, excluded: Array = []) -> Dictionary:
	var out := {}
	for property in value.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and str(property.name) not in excluded:
			out[property.name] = _plain(value.get(property.name))
	return out

func _plain(value: Variant) -> Variant:
	if value is Object: return _properties(value)
	if value is Dictionary:
		var out := {}
		for key in value: out[key] = _plain(value[key])
		return out
	if value is Array:
		var out: Array = []
		for item in value: out.append(_plain(item))
		return {"typed_builtin": value.get_typed_builtin(), "typed_class": str(value.get_typed_class_name()), "typed_script": value.get_typed_script().resource_path if value.get_typed_script() != null else "", "values": out}
	return value

func _oracle(owner: OperationPrivateState) -> Dictionary:
	var sim := owner._sim
	return {"state": _properties(sim.st, ["_idx", "_idx_n"]),
		"sim": _properties(sim, ["st", "salvo", "terrain", "detect", "supply", "morale", "victory", "cai", "decisions", "chain", "cmd", "assault", "skills"]),
		"salvo": _properties(sim.salvo, ["sim", "C", "terr"]) if sim.salvo else {},
		"terrain": _properties(sim.terrain) if sim.terrain else {},
		"detect": _properties(sim.detect, ["sim", "D", "terr"]) if sim.detect else {},
		"supply": _properties(sim.supply, ["sim", "S"]) if sim.supply else {},
		"owner_profile": _plain(owner._profile), "initial_controls": _plain(owner._controls),
		"seed": owner._seed, "hz": owner._hz, "ready": owner._ready, "busy": owner._busy}

func _profile(kind: String) -> Dictionary:
	var rules: Dictionary = PocSetup.profile().rules
	rules.world_w = 3400
	rules.world_h = 2300
	var typed_note: Array[int] = [1]
	var profile := {"profile_id": "active-replace-" + kind, "rules": rules,
		"ally": [{"name": "A", "role": "A", "ships": 30, "lv": 1, "x": 500, "y": 500, "p": 0, "flag": true}],
		"foe": [{"name": "B", "role": "B", "ships": 30, "lv": 1, "x": 750, "y": 500, "p": 0, "flag": true}],
		"reinf": [], "note": {"typed_probe": typed_note, "ordered_probe": {"first": 1, "last": 2}}}
	if kind == "poc": return profile
	var combat := SalvoFixture.combat()
	for key in ["morale", "victory", "command", "stratagem", "assault", "terrain"]: combat.erase(key)
	profile.combat = combat
	profile.ally = [SalvoFixture.def("S", 800, 450, [["SHP-05", 2], ["SHP-04", 2]], true), SalvoFixture.def("C", 925, 450, [["SHP-04", 2]])]
	profile.foe = [SalvoFixture.def("F", 1000, 450, [["SHP-02", 4]], true)]
	for fleet in profile.ally: fleet.faction_id = "liu_bei"
	profile.foe[0].faction_id = "cao_cao"
	return profile

func _new(seed: int, kind: String, controls: Array = []) -> OperationPrivateState:
	var result := Private.create(_profile(kind), seed, BattleRules.TICK_HZ, controls)
	_check(result.ok, "create " + kind)
	if not result.ok: return null
	var owner: OperationPrivateState = result.owner
	# Fixture setup suppresses AI/automatic attacks, not Detection/Supply effects.
	owner._sim.st.ai_timer = 1 << 40
	owner._sim.endless = true
	if kind == "services":
		for fleet in owner._sim.st.fleets:
			for category in fleet.next_fire: fleet.next_fire[category] = 1 << 40
		# Initially empty cargo is fixture input. Only real Supply.step refills it.
		for category in owner._sim.st.fleets[1].ammo: owner._sim.st.fleets[1].ammo[category] = 0
	return owner

func _advance(owner: OperationPrivateState, count: int, drain := true) -> void:
	for i in count:
		_check(owner.advance().ok, "public advance")
		if drain: _check(owner.drain_events().ok, "public drain")

func _capture(owner: OperationPrivateState) -> Dictionary:
	var result := owner.capture_completed()
	_check(result.ok, "capture completed")
	return result.get("packet", {})

func _retired(sim: BattleSim) -> void:
	for field in ["salvo", "detect", "supply"]:
		var module: Variant = sim.get(field)
		if module != null: _check(module.sim == null, "old binding retired " + field)

func _bindings(owner: OperationPrivateState) -> void:
	var sim := owner._sim
	for field in ["salvo", "detect", "supply"]:
		var module: Variant = sim.get(field)
		if module != null: _check(is_same(module.sim, sim), "new binding alive " + field)
	for fleet in sim.st.fleets:
		_check(is_same(sim.st.by_id(fleet.id), fleet), "new by_id fleet identity")

func _normal(seed: int, kind: String) -> void:
	var owner := _new(seed, kind)
	if owner == null: return
	var stock := 0
	if kind == "poc":
		_check(owner.issue(BattleSim.command(0, [1], "missile", 2)).ok, "actual missile issue")
		_check(owner.issue(BattleSim.command(1, [2], "fighter", 1)).ok, "actual fighter issue")
		_advance(owner, 1, false)
		_check(not owner._sim.st.missiles.is_empty() and not owner._sim.st.swarms.is_empty(), "actual in-flight attacks")
		_check(owner._sim.st.fleets[0].missile_cd > 0 and owner._sim.st.fleets[1].fighter_cd > 0, "actual active cooldowns")
	else:
		stock = owner._sim.st.fleets[0].sup_ammo
		_advance(owner, 1)
		_check(owner._sim.detect.contacts[0].has(3), "actual nonempty contact")
		# Controlled fixture relocation makes target unseen. Memory is generated
		# and aged by ordinary Detection.step, not by writing contact records.
		owner._sim.st.fleets[2].pos = Vector2(3200, 2000)
		_advance(owner, 598)
		var contact: Dictionary = owner._sim.detect.rec(0, 3)
		_check(contact.get("state") == "estimated" and contact.get("pos") != owner._sim.st.fleets[2].pos, "actual remembered contact")
		_check(owner._sim.st.fleets[1].sup_src != "" and owner._sim.st.fleets[1].sup_prog > 0 and owner._sim.st.fleets[1].supplied == 0, "actual supply pending")
		_check(owner._sim.st.fleets[0].sup_ammo == stock, "supply has not spent stock before completion")
	_check(owner.issue(BattleSim.command(0, [1], "stop")).ok, "completed public command produces event boundary")
	_check(not owner._sim._events.is_empty(), "nonempty packet event boundary")
	_check(owner.queue(BattleSim.command(0, [1], "stop")).ok, "pending public queue")
	var packet := _capture(owner)
	var packet_before: Variant = _plain(packet)
	var checkpoint := _oracle(owner)
	var prepared := Private.prepare(packet)
	_check(prepared.ok, "independent fresh reference prepares")
	if not prepared.ok:
		owner.close()
		return
	var reference: OperationPrivateState = prepared.owner
	var handle_id := owner.get_instance_id()
	_advance(owner, 3)
	_check(not _same(checkpoint, _oracle(owner)), "active timeline really progressed after capture")
	var previous: BattleSim = owner._sim
	var old_fleet := previous.st.by_id(1)
	var result := owner.restore_completed(packet)
	_check(result.ok and not result.has("owner"), "restore returns status on existing handle")
	_check(owner.get_instance_id() == handle_id and not is_same(owner._sim, previous), "same owner handle new sim")
	_check(not is_same(owner._sim.st.by_id(1), old_fleet), "fresh fleet replaces old cached identity")
	_check(_same(checkpoint, _oracle(owner)) and _same(_oracle(reference), _oracle(owner)), "replacement equals independent direct checkpoint oracle")
	_check(_same(packet_before, _plain(packet)), "successful replacement packet unchanged")
	_retired(previous)
	_bindings(owner)
	var repeat_before := _oracle(owner)
	var repeat_old: BattleSim = owner._sim
	_check(owner.restore_completed(packet).ok and _same(repeat_before, _oracle(owner)), "repeat restore itself adds no effects")
	_retired(repeat_old)
	_bindings(owner)
	_check(owner._sim._queue.size() == 1 and owner._sim.command_log.size() == packet.view.sim.command_log.size(), "preparation never consumes pending")
	# The old timeline consumed these events; snapshot restore deliberately
	# restores its earlier pending events. This is not global deduplication.
	var events := owner.drain_events()
	_check(events.ok and _same(events, reference.drain_events()) and _same(events.events, packet.view.sim._events), "snapshot pending events restore in order")
	_check(owner.drain_events().events.is_empty(), "pending events drain once per restored timeline")
	var drained_packet := _capture(owner)
	_check(owner.issue(BattleSim.command(0, [1], "move", -1, Vector2(900, 500))).ok, "temporary later timeline event")
	_check(owner.restore_completed(drained_packet).ok and owner.drain_events().events.is_empty(), "snapshot already-drained events remain empty")
	_check(_same(_oracle(owner), _oracle(reference)), "drained snapshot still equals independent reference")
	var log_size := owner._sim.command_log.size()
	var initial_missiles := owner._sim.st.missiles.size()
	var suffix_steps := 110 if kind == "poc" else 70
	for i in suffix_steps:
		_check(owner.advance().ok and reference.advance().ok, "public suffix advances")
		_check(owner._sim._queue.is_empty() and owner._sim.command_log.size() == log_size + 1, "pending command consumed exactly once")
		_check(_same(_oracle(owner), _oracle(reference)), "public suffix exact independent state")
		_check(_same(owner.drain_events(), reference.drain_events()), "public suffix ordered events")
	if kind == "services":
		_check(owner._sim.st.fleets[1].supplied == 1 and owner._sim.st.fleets[0].sup_ammo < stock, "suffix crosses actual supply completion and stock spending once")
		_check(not owner._sim.detect.contacts[0].is_empty() and owner._sim.st.tick > int(drained_packet.view.state.tick) + owner._sim.detect._period, "suffix crosses actual detection evaluation")
	else:
		_check(owner._sim.st.missiles.size() < initial_missiles, "suffix resolves actual in-flight missile")
	var stable := _oracle(owner)
	packet.view.fleets[0].route.append(Vector2(1, 2))
	var exposed := owner.observe()
	exposed.fleets[0].route.append(Vector2(3, 4))
	_check(_same(stable, _oracle(owner)) and _same(stable, _oracle(reference)), "packet and public observation have no mutable alias")
	cases.append({"seed": seed, "kind": kind, "suffix_steps": suffix_steps, "tick": owner._sim.st.tick, "clock_ms": owner._sim.st.clock_ms, "supplied": owner._sim.st.fleets[1].supplied if kind == "services" else 0})
	owner.close()
	reference.close()

func _valid_candidate(packet: Dictionary, label: String) -> void:
	var result := Private.prepare(packet)
	_check(result.ok, "different context is independently valid " + label)
	if result.ok: result.owner.close()

func _reject(owner: OperationPrivateState, packet: Dictionary, label: String, expected: String) -> void:
	var before := _oracle(owner)
	var sim: BattleSim = owner._sim
	var packet_before: Variant = _plain(packet)
	var result := owner.restore_completed(packet)
	refusal_calls += 1
	_check(not result.ok and not result.has("owner") and result.get("error") == expected, "expected named refusal " + label)
	_check(is_same(owner._sim, sim) and _same(before, _oracle(owner)) and _same(packet_before, _plain(packet)), "failed replacement preserves sim owner packet " + label)
	_check(not owner._busy and owner.issue(BattleSim.command(0, [1], "stop")).ok, "failure restores busy and permits next public input " + label)
	rejections[label] = result.get("error", "UNEXPECTED_SUCCESS")

func _negative() -> void:
	var owner := _new(1, "poc")
	if owner == null: return
	var packet := _capture(owner)
	var bad: Dictionary = packet.duplicate(true)
	bad.view.fleets.back().form.clear()
	_reject(owner, bad, "late_empty_form", "fleet_empty_form")
	bad = packet.duplicate(true)
	var untyped: Array = [1]
	bad.profile.note.typed_probe = untyped
	_check(Private.Service._same(packet.profile, bad.profile), "metadata-only context would escape Service comparator")
	_valid_candidate(bad, "typed metadata only")
	_reject(owner, bad, "different_profile", "replacement_context_mismatch")
	bad = packet.duplicate(true)
	bad.profile.note.ordered_probe = {"last": 2, "first": 1}
	_valid_candidate(bad, "dictionary insertion order only")
	_reject(owner, bad, "different_profile", "replacement_context_mismatch")
	var different := _new(2, "poc")
	if different != null:
		bad = _capture(different)
		_valid_candidate(bad, "seed")
		_reject(owner, bad, "different_seed", "replacement_context_mismatch")
		different.close()
	different = _new(1, "poc", ["delegate", "delegate"])
	if different != null:
		bad = _capture(different)
		_valid_candidate(bad, "explicit delegate versus empty initial controls")
		_reject(owner, bad, "different_controls", "replacement_context_mismatch")
		different.close()
	bad = packet.duplicate(true)
	bad.hz = 20
	_reject(owner, bad, "unsupported_hz", "unsupported_hz")
	var before := _oracle(owner)
	var sim: BattleSim = owner._sim
	var stamp: Variant = _plain(packet)
	owner._busy = true
	var busy := owner.restore_completed(packet)
	refusal_calls += 1
	_check(not busy.ok and busy.get("error") == "busy" and owner._busy and is_same(owner._sim, sim), "busy refuses before preparation and retains existing busy")
	owner._busy = false
	_check(_same(before, _oracle(owner)) and _same(stamp, _plain(packet)), "busy guard no mutation")
	rejections.busy = busy.get("error", "UNEXPECTED_SUCCESS")
	owner._ready = false
	var unprepared := owner.restore_completed(packet)
	refusal_calls += 1
	_check(not unprepared.ok and unprepared.get("error") == "unprepared_owner" and not owner._ready and not owner._busy and is_same(owner._sim, sim), "unprepared refuses before swap")
	owner._ready = true
	_check(_same(before, _oracle(owner)) and _same(stamp, _plain(packet)), "unprepared guard no mutation")
	rejections.unprepared = unprepared.get("error", "UNEXPECTED_SUCCESS")
	_check(owner.restore_completed(packet).ok and owner.issue(BattleSim.command(0, [1], "stop")).ok, "normal restore and issue recover after all failures")
	owner.close()
	var closed := owner.restore_completed(packet)
	refusal_calls += 1
	_check(not closed.ok and closed.get("error") == "unprepared_owner" and owner._sim == null and not owner._ready and not owner._busy and _same(stamp, _plain(packet)), "closed owner cannot adopt runtime")
	rejections.closed = closed.get("error", "UNEXPECTED_SUCCESS")

func _run() -> void:
	var fixture_script: Script = SalvoFixture
	_check(fixture_script.resource_path == "res://tests/lib/salvo_fixture.gd", "canonical test fixture path")
	for seed in SEEDS:
		for kind in ["poc", "services"]: _normal(seed, kind)
	_negative()
	_check(cases.size() == 20 and cases.filter(func(c): return c.kind == "poc").size() == 10 and cases.filter(func(c): return c.kind == "services").size() == 10, "complete twenty active replacement cases")
	_check(rejections.size() == 8 and refusal_calls == 9, "complete eight refusal names nine calls including two profile subcases")
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	_check(file != null, "evidence output opens")
	if file != null:
		file.store_string(JSON.stringify({"scope": "RESTRICTED_SAME_CONTEXT_ACTIVE_REPLACEMENT", "overall": "NOT_READY", "cases": cases, "checks": checks, "rejections": rejections, "refusal_calls": refusal_calls, "failed": failed}, "  "))
		file.close()
	print("I01B_ACTIVE_REPLACE_", "FAIL" if failed else "PASS", " cases=", cases.size(), " checks=", checks, " rejections=", rejections.size(), " refusal_calls=", refusal_calls)
	quit(1 if failed else 0)
