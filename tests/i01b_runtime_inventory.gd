extends SceneTree

# P2a: selected B0 legacy values, not C0, save schema or operation integration.
const SEEDS := [0, 1, 20824, 20825, 20826, 90210, 123456789, 2147483647, 2147483648, 4294967295]
const SUP_FIELDS := ["sup_src", "sup_prog", "sup_since", "sup_still", "sup_pos", "sup_n", "sup_ammo", "sup_mat", "sup_hold", "sup_first"]
const STATE_FIELDS := ["hz", "seed_id", "tick", "clock_ms", "next_id", "next_event_id", "form_counter", "ai_timer", "over", "win", "end_reason", "end_tick", "end_ms"]
const OUT := "res://tmp/i01b-runtime-inventory-20261028/observations.json"
var checks := 0
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failed = true
		push_error("I01B_P2A_FAIL: " + message)
	return ok

# Strict types, exact values and insertion order; no JSON rounding oracle.
func _same(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b): return false
	if a is Dictionary:
		var ak: Array = a.keys()
		var bk: Array = b.keys()
		if not _same(ak, bk): return false
		for key in ak:
			if not _same(a[key], b[key]): return false
		return true
	if a is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not _same(a[i], b[i]): return false
		return true
	return a == b

# Typed diagnostic representation, not a loadable runtime snapshot.
func _typed(value: Variant) -> Dictionary:
	var out := {"type": type_string(typeof(value))}
	if value is Dictionary:
		var entries: Array = []
		for key in value:
			entries.append({"key": _typed(key), "value": _typed(value[key])})
		out.entries = entries
	elif value is Array:
		var items: Array = []
		for item in value: items.append(_typed(item))
		out.items = items
	elif value is Vector2:
		out.x = value.x
		out.y = value.y
	elif typeof(value) == TYPE_FLOAT:
		out.value = value
		out.ieee64_hex = PackedFloat64Array([value]).to_byte_array().hex_encode()
	else:
		out.value = value
	return out

func _observe(sim: BattleSim) -> Dictionary:
	var state := {}
	for field in STATE_FIELDS: state[field] = sim.st.get(field)
	var fleet_rows: Array = []
	for f in sim.st.fleets:
		var row := {"id": f.id, "side": f.side, "faction": f.faction}
		for field in SUP_FIELDS: row[field] = f.get(field)
		fleet_rows.append(row)
	var detection := {"status": "observed_absent", "branch": "BattleSim._init: combat absent or lacks detection"}
	if sim.detect != null:
		detection = {"status": "observed_active", "contacts": sim.detect.contacts.duplicate(true), "period_ticks": sim.detect._period, "initial_confidence_bp": sim.detect._conf0}
	var supply := {"status": "observed_absent", "branch": "BattleSim._init: combat absent or lacks supply"}
	if sim.supply != null:
		supply = {"status": "observed_active", "ship": sim.supply.ship, "need_bp_ticks": sim.supply.need, "light_ticks": sim.supply.light_ticks, "still_eps_coordinate_per_tick": sim.supply.still_eps, "bases": sim.supply.bases.duplicate(true)}
	return {"state": state, "first_hit_tick": sim.first_hit_tick, "sub_ms": sim.sub_ms, "command_log": sim.command_log.duplicate(true), "pending_queue": sim._queue.duplicate(true), "events": sim._events.duplicate(true), "detection": detection, "supply": supply, "fleets": fleet_rows}

func _validate(sim: BattleSim, profile: Dictionary, label: String, seed_id: int) -> void:
	_check(sim.st.seed_id == seed_id and sim.st.hz == BattleRules.TICK_HZ and sim.st.tick == 0 and sim.st.clock_ms == 0, "B0 actual clock/seed")
	_check(sim.sub_ms == 0 and sim.first_hit_tick == -1 and not sim.st.over, "B0 before first substep/end")
	_check(sim.command_log.is_empty() and sim._queue.is_empty(), "no human inputs before B0")
	var ids: Array = []
	for f in sim.st.fleets:
		_check(not ids.has(f.id) and f.id < sim.st.next_id, "unique fleet IDs below actual next_id")
		ids.append(f.id)
		_check(typeof(f.sup_src) == TYPE_STRING and typeof(f.sup_pos) == TYPE_VECTOR2 and typeof(f.sup_prog) == TYPE_INT, "fleet selected supply types")
	var combat: Dictionary = profile.get("combat", {})
	if label == "poc":
		_check(combat.is_empty() and sim.detect == null and sim.supply == null, "POC constructor absence branch")
		return
	_check(combat.has("detection") and combat.has("supply") and sim.detect != null and sim.supply != null, "RC constructor active branches")
	if sim.detect == null or sim.supply == null: return
	_check(is_same(sim.detect.sim, sim) and is_same(sim.supply.sim, sim), "module self references")
	_check(is_same(sim.detect.terr, sim.terrain), "RC detection terrain ownership")
	_check(is_same(sim.detect.D, combat.detection) and is_same(sim.supply.S, combat.supply), "module configuration ownership")
	_check(_same(sim.detect.contacts, [{}, {}]), "B0 contacts empty per side only")
	_check(typeof(sim.detect._period) == TYPE_INT and sim.detect._period == maxi(1, BattleRules.ticks(float(combat.detection.eval_period_s), sim.st.hz)), "detection period ticks formula")
	_check(sim.detect._conf0 == int(sim.rs.rt("fog_override.estimated_confidence_basis_points", combat.detection.confidence_bp)), "detection initial confidence source")
	_check(sim.supply.ship == str(combat.supply.ship_type_id) and sim.supply.need == BattleRules.ticks(float(combat.supply.stationary_s), sim.st.hz) * BattleRules.BP, "supply type and need source")
	_check(sim.supply.light_ticks == BattleRules.ticks(float(combat.supply.repair.light_recover_s), sim.st.hz) and typeof(sim.supply.still_eps) == TYPE_FLOAT and sim.supply.still_eps == float(combat.supply.still_eps_px_s) / sim.st.hz, "supply units and source formulas")
	_check(not sim.supply.bases.is_empty() and sim.supply.bases.size() == combat.supply.bases.size(), "actual active base records")
	for i in sim.supply.bases.size():
		var base: Dictionary = sim.supply.bases[i]
		var source: Dictionary = combat.supply.bases[i]
		var expected_side := -1
		for f in sim.st.fleets:
			if sim.supply.allied(f.faction, str(source.faction_id)): expected_side = f.side
		_check(_same(base.keys(), ["key", "faction", "side", "pos"]) and typeof(base.side) == TYPE_INT and typeof(base.pos) == TYPE_VECTOR2, "base actual ordered shape/types")
		_check(base.key == str(source.id) and base.faction == str(source.faction_id) and base.side == expected_side and base.pos == Vector2(float(source.position[0]), float(source.position[1])), "base source identity/side/position")
	for f in sim.st.fleets:
		_check(f.sup_n == sim.supply.ships_of(f) and f.sup_ammo == f.sup_n * int(combat.supply.per_ship.ammo) and f.sup_mat == f.sup_n * int(combat.supply.per_ship.materials) and f.sup_pos == f.pos, "fleet supply constructor actual fields")

func _identity(a: BattleSim, b: BattleSim) -> void:
	_check(not is_same(a, b) and not is_same(a.st, b.st), "fresh object identity")
	for field in ["fleets", "missiles", "swarms"]:
		_check(not is_same(a.st.get(field), b.st.get(field)), "fresh state container " + field)
	for field in ["command_log", "_queue", "_events"]:
		_check(not is_same(a.get(field), b.get(field)), "fresh sim container " + field)
	if a.detect != null and b.detect != null:
		_check(not is_same(a.detect, b.detect) and not is_same(a.detect.contacts, b.detect.contacts), "fresh detection identities")
		for side in 2: _check(not is_same(a.detect.contacts[side], b.detect.contacts[side]), "fresh side contact container")
	if a.supply != null and b.supply != null:
		_check(not is_same(a.supply, b.supply) and not is_same(a.supply.bases, b.supply.bases), "fresh supply identities")
		for i in a.supply.bases.size(): _check(not is_same(a.supply.bases[i], b.supply.bases[i]), "fresh base record identity")

func _release(sim: BattleSim) -> void:
	# Only after every observation/check, break legacy RefCounted backreferences.
	for field in ["morale", "victory", "salvo", "detect", "supply", "chain", "cmd", "assault", "skills", "decisions"]:
		var module: Variant = sim.get(field)
		if module != null:
			for property in module.get_property_list():
				if property.name == "sim": module.set("sim", null)

func _run() -> void:
	var retained := {}
	var baselines := {}
	var observations: Array = []
	for fresh in 2:
		var labels: Array = ["poc", "red_cliffs_standard"]
		var seeds: Array = SEEDS.duplicate()
		if fresh == 1:
			labels.reverse()
			seeds.reverse()
		for label in labels:
			for seed_id in seeds:
				var profile: Dictionary = PocSetup.profile() if label == "poc" else ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", "표준")
				if not _check(not profile.is_empty(), "required existing profile"): quit(1); return
				var source_before: Dictionary = profile.duplicate(true)
				var sim := BattleSim.new(seed_id, BattleRules.TICK_HZ, profile)
				_check(_same(profile, source_before), "constructor profile nonmutation")
				var before := _observe(sim)
				_validate(sim, profile, label, seed_id)
				var value := _observe(sim)
				_check(_same(before, value) and _same(value, _observe(sim)) and _same(profile, source_before), "selected observation/profile nonmutation")
				var copy: Dictionary = value.duplicate(true)
				copy.state.tick = -999
				copy.fleets.append({"probe": true})
				_check(_same(value, before) and _same(_observe(sim), before), "observation deep-copy probe only")
				var key := "%s/%d" % [label, seed_id]
				if fresh == 0:
					retained[key] = sim
					baselines[key] = value
				else:
					_check(_same(value, baselines[key]), "fresh exact typed values " + key)
					_identity(retained[key], sim)
					_check(_same(_observe(retained[key]), baselines[key]), "first fresh selected state unchanged")
					_release(retained[key])
					retained.erase(key)
					_release(sim)
				observations.append({"profile": label, "seed": seed_id, "fresh": fresh, "boundary": "B0_NOT_C0", "save_policy": "UNCLASSIFIED", "selected_values": _typed(value)})
	_check(observations.size() == 40 and retained.is_empty(), "40 observations and released retained samples")
	var report := {"scope": "selected legacy B0 observation only", "C0": "NOT_VALIDATED", "original_I01_I01b_A04_A05_A06": "NOT_READY", "save_policy": "UNCLASSIFIED", "observation_count": observations.size(), "checks": checks, "passed": not failed, "identity_coverage": ["sim", "st", "st.fleets", "st.missiles", "st.swarms", "command_log", "_queue", "_events", "detect", "detect.contacts", "detect.contacts[side]", "supply", "supply.bases", "supply.bases[i]"], "limitations": ["No full state alias absence claim", "Deep-copy probe covers observation copies only", "Empty B0 contacts do not cover operational contact schema", "No host control/projection/C0, save/restore/suffix or geometry completion"], "observations": observations}
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if not _check(file != null, "evidence file open"): quit(1); return
	file.store_string(JSON.stringify(report, "\t", false))
	file.close()
	if failed: quit(1); return
	print("I01B_P2A_B0_INVENTORY_PASS cases=40 profiles=2 seeds=10 fresh=2 checks=%d" % checks)
	print("B0_NOT_C0; SAVE_POLICY=UNCLASSIFIED; ORIGINAL_I01_I01B_A04_A05_A06=NOT_READY")
	quit(0)
