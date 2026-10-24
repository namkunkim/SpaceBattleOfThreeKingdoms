extends RefCounted

# Local diagnostics only. Never changes simulation state or drains core events.
var file: FileAccess
var path := ""
var seq := 0
var last_tick := -1
var last_status_tick := -1
var last_status := {}
var last_ui := ""

func start(host: Node) -> void:
	if file:
		write(host, "session_closed", {"reason": "restart"})
		file.close()
	file = null
	seq = 0
	last_tick = -1
	last_status_tick = -1
	last_status.clear()
	last_ui = ""
	var dir := "user://battle_traces"
	var err := DirAccess.make_dir_recursive_absolute(dir)
	if err != OK:
		push_warning("[TRACE] Cannot create log directory: %s" % error_string(err))
		return
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	path = "%s/battle-%s-%d-%d.jsonl" % [dir, stamp, OS.get_process_id(), Time.get_ticks_usec()]
	file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("[TRACE] Cannot open log: %s" % error_string(FileAccess.get_open_error()))
		return
	print("[TRACE] ", ProjectSettings.globalize_path(path))
	write(host, "session_start", {"profile": host.sim.profile_id, "profile_path": host.profile_def,
		"seed": host.battle_seed, "difficulty": host.difficulty, "hz": host.sim.st.hz,
		"move_mul": host.move_mul, "turn_mul": host.turn_mul, "world": host.sim.rs.world,
		"engine": Engine.get_version_info().string, "fleet_state": fleets(host.sim)})

func fleets(sim: BattleSim) -> Array:
	var rows := []
	for f in sim.st.fleets:
		if f.side != 0:
			continue
		rows.append({"id": f.id, "sq": f.sq_id, "name": f.name, "is_flag": f.is_flag,
			"pos": f.pos, "has_move": f.has_move, "move_to": f.move_to, "target_id": f.target_id,
			"heading": f.heading, "speed": f.speed, "control": f.control, "posture": f.posture,
			"morale_bp": f.morale_bp, "mstate": f.mstate, "out": f.out, "dead": f.dead,
			"forced_retreat": sim.morale.forced(f) if sim.morale else false,
			"retreat_order": f.retreat_order, "ships_milli": f.ships, "hull": f.hull,
			"cmdr_state": f.cmdr_state, "confuse_until": f.confuse_until, "in_cmd": f.in_cmd,
			"formation": f.formation_id, "form_to": f.form_to, "flip_wait": f.flip_wait})
	return rows

func write(host: Node, kind: String, data := {}) -> void:
	if file == null:
		return
	seq += 1
	var row := {"v": 1, "seq": seq, "wall_time": Time.get_datetime_string_from_system(),
		"mono_ms": Time.get_ticks_msec(), "tick": host.sim.st.tick,
		"sim_ms": host.sim.st.clock_ms, "kind": kind, "data": data}
	file.store_line(JSON.stringify(_json(row)))
	file.flush() # Preserve the last rejection even if the game is closed abruptly.

func sample(host: Node) -> void:
	if file == null:
		return
	var ids := []
	for f in host.selected:
		ids.append(f.id)
	var ui := {"state": host.G.state, "selected": ids, "placing": host.placing,
		"speed": host.G.speed, "slow": host.G.slow, "focused": host.get_window().has_focus()}
	var key := JSON.stringify(ui)
	if key != last_ui:
		last_ui = key
		write(host, "ui_state", ui)
	if last_status_tick == host.sim.st.tick:
		return
	last_status_tick = host.sim.st.tick
	for row in fleets(host.sim):
		var status := [row.mstate, row.out, row.control, row.cmdr_state, row.confuse_until]
		if last_status.get(row.id, []) != status:
			last_status[row.id] = status
			write(host, "fleet_status", row)
	if host.sim.st.tick - last_tick >= host.sim.st.hz or last_tick < 0:
		last_tick = host.sim.st.tick
		write(host, "snapshot", {"fleets": fleets(host.sim),
			"army_morale_bp": [host.sim.morale.army_bp(0), host.sim.morale.army_bp(1)] if host.sim.morale else []})

func event(host: Node, e: Dictionary) -> void:
	if e.kind in ["rejected", "battle_end", "morale_crisis", "retreat", "surrender", "fleet_sunk", "charge", "ai_charge_decision"]:
		write(host, "core_event", {"event": e, "fleets": fleets(host.sim)})
	if e.kind == "battle_end":
		write(host, "battle_end", {"win": host.sim.st.win, "reason": host.sim.st.end_reason,
			"result": host.sim.st.result, "fleets": fleets(host.sim)})

func _json(value: Variant) -> Variant:
	if value is Vector2:
		return [value.x, value.y]
	if value is Dictionary:
		var out := {}
		for k in value:
			out[str(k)] = _json(value[k])
		return out
	if value is Array:
		var out := []
		for item in value:
			out.append(_json(item))
		return out
	return value
