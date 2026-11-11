extends SceneTree

const BATTLE := preload("res://scenes/FleetBattle3D.tscn")
const OUTPUT := "user://red-cliffs-legacy-geometry.json"
const SEED := 20824
const GEOMETRY := "res://data/scenarios/p05_p07_first_operation_dev_v1.json"

var _checks := 0
var _fails := 0
var _effective := {}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var brief := BattleBrief.new()
	brief.seed = SEED
	var source := brief.profile()
	var before := OperationProfile.canonical(source)
	var link := root.get_node("WorldLink")
	link.brief = brief
	var battle := BATTLE.instantiate()
	battle.profile_patch = _observe_effective
	root.add_child(battle)
	var host: BattleSim = battle.sim
	var resolver := AutoResolver.new(brief)
	var automatic_ready := resolver._prepare()
	if not _check(host != null and not _effective.is_empty() and automatic_ready, "actual host and auto preparation"):
		_finish()
		return
	var automatic: BattleSim = resolver.sim
	var replay := BattleSim.replay(SEED, BattleRules.TICK_HZ, [], 0, _effective.duplicate(true))
	var scale := Vector2(host.rs.world.x / source.rules.world_w, host.rs.world.y / source.rules.world_h)
	_check(scale.x != scale.y, "legacy direct uses anisotropic scaling")
	_check(automatic.rs.world == Vector2(source.rules.world_w, source.rules.world_h), "legacy auto retains source extent")
	_check(host.st.tick == 0 and host.st.clock_ms == 0 and automatic.st.tick == 0 and replay.st.tick == 0,
		"observe actual native initializers before a tick")
	_check(_positions_match(host, automatic, scale), "all actual fleet positions use one axis-specific transform")
	_check(_positions_match(host, replay, Vector2.ONE), "native replay with captured effective profile recreates positions")
	_check(host.st.fleets[0].control == "direct" and replay.st.fleets[0].control != "direct",
		"native replay at tick zero lacks the legacy host control assignment")
	_check(before == OperationProfile.canonical(brief.profile()), "source loader remains unchanged after host build")

	var exits := []
	for side in [0, 1]:
		var center: Vector2 = host.morale.exit_point(side)
		var source_center: Vector2 = automatic.morale.exit_point(side)
		var radius: float = host.morale.exit_radius(side)
		var edge: float = host.R.edge
		var legal := Vector2(clampf(center.x, edge, host.rs.world.x - edge), clampf(center.y, edge, host.rs.world.y - edge))
		_check(center.is_equal_approx(source_center * scale) and radius == automatic.morale.exit_radius(side)
			and legal.distance_to(center) <= radius, "legacy exit keeps a center-only legal witness")
		exits.append({"side": side, "source": _xy(source_center), "effective": _xy(center), "radius": radius,
			"nearest_center_only_witness": _xy(legal), "whole_disk_radius_limit_at_wall": radius})
	var bases := []
	for i in host.supply.bases.size():
		var base: Dictionary = host.supply.bases[i]
		var raw: Dictionary = automatic.supply.bases[i]
		var point: Vector2 = base.pos
		_check(base.key == raw.key and point.is_equal_approx(raw.pos * scale), "native supply base matches source transform")
		bases.append({"id": base.key, "source": _xy(raw.pos), "effective": _xy(point),
			"service_radius": host.supply.S.base_radius,
			"wall_clearance_at_center": minf(minf(point.x, point.y), minf(host.rs.world.x - point.x, host.rs.world.y - point.y))})
	var profile_def := ProfileLoader.read_json(BattleBrief.PROFILE_DEF)
	var hashes := {}
	for path in [BattleBrief.PROFILE_DEF, profile_def.scenario_path, profile_def.base_profile,
			profile_def.combat_rules_path, profile_def.ai_rules_path]:
		hashes[path] = FileAccess.get_sha256(path)
	var report := {
		"scope": "legacy_geometry_observation_only", "product_a04": "NOT_READY",
		"profile_id": host.profile_id, "difficulty": brief.difficulty, "seed": SEED,
		"source": {"extent": _xy(automatic.rs.world), "effective_profile_hash": before.sha256_text()},
		"effective": {"extent": _xy(host.rs.world), "profile_hash": OperationProfile.canonical(_effective).sha256_text(),
			"scale_xy": _xy(scale), "move_mul": battle.move_mul, "turn_mul": battle.turn_mul},
		"source_file_sha256": hashes, "exits": exits, "supply_bases": bases,
		"legacy_direct": _fleet_rows(host), "legacy_auto": _fleet_rows(automatic),
		"native_replay_tick_zero": _fleet_rows(replay),
		"missing_product_contract": ["approved source routes and service ingress/egress",
			"whole-formation envelope per supported roster and transition", "product common C0 control assignment"],
	}
	var aligned: BattleSim
	if OS.get_cmdline_user_args().has("--geometry-candidate"):
		aligned = BattleSim.new(SEED, BattleRules.TICK_HZ, _effective.duplicate(true))
		report.geometry_candidate = _candidate(host, aligned, replay)
	var output := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if _check(output != null, "write evidence"):
		output.store_string(JSON.stringify(report, "\t", true, true))
		output.close()
	root.remove_child(battle)
	battle.free()
	for sim in [host, automatic, replay, aligned]:
		if sim != null:
			_release(sim)
	_finish()

# Candidate only: apply the existing direct control contract to the two
# independently initialized native consumers before their first observation.
func _direct_controls(sim: BattleSim) -> void:
	for fleet in sim.st.fleets:
		if fleet.side == 0 and fleet.faction == "liu_bei":
			fleet.control = "direct"

func _candidate(host: BattleSim, headless: BattleSim, replay: BattleSim) -> Dictionary:
	_direct_controls(headless)
	_direct_controls(replay)
	var projection := host.projection(0)
	var fingerprint := host.fingerprint()
	_check(_fleet_rows(host) == _fleet_rows(headless) and _fleet_rows(host) == _fleet_rows(replay)
		and projection == headless.projection(0) and projection == replay.projection(0)
		and fingerprint == headless.fingerprint() and fingerprint == replay.fingerprint(),
		"opt-in same effective input and direct C0 controls match all native initializers")

	var renderer := FleetRenderer.new()
	var geometry: Dictionary = ProfileLoader.read_json(GEOMETRY).space
	var rows := []
	var ids := host.salvo.formation_ids()
	var radii := {}
	var hull_guards := {}
	for fleet in host.st.fleets:
		var max_hull := 0.0
		var count := 0
		for type_id in fleet.comp0:
			count += int(fleet.comp0[type_id])
			var length: float = FleetRenderer.CLASS_LEN[renderer._model_class(type_id)]
			var corner := Vector2(length * FleetRenderer.HULL_STRETCH.x,
				length * FleetRenderer.SHIP_WIDTH / FleetRenderer.MODEL_LEN).length() / (2.0 * CameraRig.S)
			max_hull = maxf(max_hull, corner)
		if fleet.is_flag:
			max_hull *= 1.8 # Existing renderer flagship multiplier.
		var outer := 0.0
		var formation := ""
		for i in ids.size():
			var slot_radius := 0.0
			for slot: Vector3 in renderer.formation_points(BattleRules.FORM_SHAPE[i], count):
				slot_radius = maxf(slot_radius, Vector2(slot.x, slot.z).length())
			if slot_radius + max_hull > outer:
				outer = slot_radius + max_hull
				formation = ids[i]
		var guarded: float = outer + geometry.safety_margin + geometry.center_tolerance
		hull_guards[fleet.sq_id] = max_hull + geometry.safety_margin + geometry.center_tolerance
		radii[fleet.sq_id] = guarded
		rows.append({"roster_id": fleet.sq_id, "actual_ship_count": count,
			"limiting_nominal_formation": formation, "nominal_disk_upper_bound": outer,
			"guarded_disk_upper_bound": guarded})

	var fleet: FleetState = host.st.fleets[0]
	var radius: float = radii[fleet.sq_id]
	var world: Vector2 = host.rs.world
	var base: Vector2 = host.supply.bases[0].pos
	var service_radius := float(host.supply.S.base_radius)
	var old_exit := host.morale.exit_point(0)
	var exit_radius := host.morale.exit_radius(0)
	var start := fleet.pos
	var stop := _inside_disk_center(base, world, radius)
	var exit_witness := _inside_disk_center(old_exit, world, radius)
	var inward_shift := maxf(0.0, exit_witness.x - old_exit.x - exit_radius)
	var candidate_center := old_exit + Vector2(inward_shift, 0)
	_check(radius > exit_radius and exit_witness.distance_to(old_exit) > exit_radius,
		"guarded disk refutes unchanged wall exit")
	_check(_inside_disk_center(start, world, radius).is_equal_approx(start)
		and stop.distance_to(base) <= service_radius and stop != start and stop != exit_witness,
		"actual spawn and service stop admit distinct inbound and outbound segments")
	_check(is_equal_approx(exit_witness.distance_to(candidate_center), exit_radius)
		and _inside_disk_center(exit_witness, world, radius).is_equal_approx(exit_witness),
		"separate shifted exit has a whole-disk witness at unchanged arrival radius")
	var dynamic := _dynamic_candidate(headless, renderer, radii, float(hull_guards[fleet.sq_id]), exit_witness, float(geometry.safety_margin))
	renderer.free()
	print("RED_CLIFFS_CANDIDATE fleet=%s radius=%.3f exit_shift=%.3f c0=%s" %
		[fleet.sq_id, radius, inward_shift, fingerprint])
	return {"status": "GEOMETRY_CANDIDATE_ONLY", "envelope": geometry.envelope,
		"nominal_envelopes": rows, "c0_fingerprint": fingerprint, "dynamic": dynamic,
		"witness": {"roster_id": fleet.sq_id, "radius": radius, "service_center": _xy(base),
			"service_radius": service_radius, "inbound": [_xy(start), _xy(stop)],
			"outbound": [_xy(stop), _xy(exit_witness)], "legacy_exit": _xy(old_exit),
			"separate_exit_center": _xy(candidate_center), "exit_radius": exit_radius,
			"exit_center_inward_shift": inward_shift},
		"scope": "nominal slots and rectangular wall only; no dynamic hull, obstruction, traffic or policy approval"}

func _dynamic_candidate(sim: BattleSim, renderer: FleetRenderer, radii: Dictionary, hull_guard: float, gate: Vector2, margin: float) -> Dictionary:
	var first := sim.st.fleets[0]
	var second := sim.st.fleets[1]
	var from := first.formation_id
	var ids := sim.salvo.formation_ids()
	var to := "FRM-01"
	var count := 0
	for ships in first.comp0.values():
		count += int(ships)
	var from_slots := renderer.formation_points(BattleRules.FORM_SHAPE[ids.find(from)], count)
	var to_slots := renderer.formation_points(BattleRules.FORM_SHAPE[ids.find(to)], count)
	sim.issue(BattleSim.command(0, [first.id], "formation", -1, Vector2.ZERO, {"id": to}))
	var total: int = first.form_left
	_check(total > 0 and first.form_to == to, "native formation command starts timed transition")
	var maximum := 0.0
	var samples := 0
	var remaining := total
	while first.form_left > 0 and samples < total:
		sim.step()
		samples += 1
		_check(first.form_left == remaining - 1, "native formation progresses by one tick")
		remaining = first.form_left
		var fraction := 1.0 - float(remaining) / total
		for i in count:
			var slot: Vector3 = from_slots[i].lerp(to_slots[i], fraction)
			maximum = maxf(maximum, Vector2(slot.x, slot.z).length())
	var events := sim.drain_events()
	_check(samples == total and first.formation_id == to and maximum + hull_guard <= radii[first.sq_id]
		and events.any(func(event): return event.kind == "formation_changed" and event.sq == first.id),
		"timed native transition completes and nominal slot samples stay inside upper bound")

	var r1: float = radii[first.sq_id]
	var r2: float = radii[second.sq_id]
	var required := r1 + r2
	var pitch := required + margin
	var near := gate + Vector2(pitch, 0)
	var far := gate + Vector2(2.0 * pitch, 0)
	var simultaneous := _segment_distance(Vector2.ZERO, near - far, Vector2.ZERO)
	var blocked := _segment_distance(near, far, gate)
	var near_first := _segment_distance(far, near, gate)
	var world: Vector2 = sim.rs.world
	var inside := (_inside_disk_center(near, world, r1).is_equal_approx(near)
		and _inside_disk_center(far, world, r2).is_equal_approx(far)
		and _inside_disk_center(gate, world, r1).is_equal_approx(gate)
		and _inside_disk_center(gate, world, r2).is_equal_approx(gate))
	_check(inside and simultaneous < required and blocked < required and near_first >= required,
		"candidate rejects simultaneous entry and occupied lane but admits near-first departure")

	var effect_zones := []
	for zone in sim.terrain.zones:
		var rect: Array = zone.rect
		var midpoint := Vector2(rect[0] + rect[2] * 0.5, rect[1] + rect[3] * 0.5)
		effect_zones.append({"id": zone.id, "move_cost_bp": sim.terrain.move_cost_bp(midpoint)})
	_check(effect_zones.any(func(zone): return zone.move_cost_bp > BattleRules.BP),
		"native terrain data produces movement costs")
	var service_radius := float(sim.supply.S.base_radius)
	_check(r1 > service_radius, "full disk cannot fit within unchanged service circle")

	return {"formation": {"from": from, "to": to, "ticks": samples, "max_sampled_nominal_slot_radius": maximum, "max_sampled_guarded_disk": maximum + hull_guard},
		"traffic": {"near": _xy(near), "far": _xy(far), "gate": _xy(gate), "minimum_separation": required,
			"simultaneous_distance": simultaneous, "occupied_lane_distance": blocked, "near_first_clearance": near_first,
			"sequence": ["near exits while far waits", "far follows after near clears"]},
		"terrain_effects_not_hard_blockers": effect_zones, "service_whole_disk_fits": false}

func _segment_distance(point: Vector2, from: Vector2, to: Vector2) -> float:
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point, from, to))

func _inside_disk_center(point: Vector2, world: Vector2, radius: float) -> Vector2:
	return Vector2(clampf(point.x, radius, world.x - radius), clampf(point.y, radius, world.y - radius))

func _observe_effective(profile: Dictionary) -> void:
	_effective = profile.duplicate(true)

func _positions_match(actual: BattleSim, reference: BattleSim, scale: Vector2) -> bool:
	if actual.st.fleets.size() != reference.st.fleets.size():
		return false
	for i in actual.st.fleets.size():
		var a := actual.st.fleets[i]
		var b := reference.st.fleets[i]
		if a.id != b.id or a.sq_id != b.sq_id or not a.pos.is_equal_approx(b.pos * scale) or a.comp0 != b.comp0:
			return false
	return true

func _fleet_rows(sim: BattleSim) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for fleet in sim.st.fleets:
		result.append({"id": fleet.id, "roster_id": fleet.sq_id, "side": fleet.side, "control": fleet.control,
			"position": _xy(fleet.pos), "formation": fleet.formation_id,
			"composition": fleet.comp0.duplicate(), "display_slot_count": fleet.form.size(), "wait_ticks": fleet.wait})
	return result

func _xy(value: Vector2) -> Array:
	return [value.x, value.y]

func _release(sim: BattleSim) -> void:
	for key in ["salvo", "detect", "supply", "cai", "morale", "victory", "cmd", "skills", "decisions", "chain", "assault"]:
		var module: Variant = sim.get(key)
		if module is Object and "sim" in module:
			module.sim = null

func _check(ok: bool, message: String) -> bool:
	_checks += 1
	if not ok:
		_fails += 1
		push_error("RED_CLIFFS_GEOMETRY_FAIL " + message)
	return ok

func _finish() -> void:
	print("RED_CLIFFS_LEGACY_GEOMETRY_%s checks=%d output=%s" % ["PASS" if _fails == 0 else "FAIL",
		_checks, ProjectSettings.globalize_path(OUTPUT)])
	quit(0 if _fails == 0 else 1)

