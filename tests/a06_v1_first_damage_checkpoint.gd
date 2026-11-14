extends SceneTree
## Test-only approved v1 first-damage checkpoint evidence. No product changes.
const Adapter := preload("res://scripts/first_operation_adapter.gd")
const Product := preload("res://scripts/first_operation_source_reference.gd")
const Host := preload("res://scripts/first_operation_host.gd")
const Store := preload("res://scripts/first_operation_save_store.gd")
const Service := preload("res://core/battle/operation_service_state.gd")
const PIN := "32be342a94824d35c923bad15a04595d64d288dbe5ebb5e7b9f8350381c504d7"
const MARKS := [1061, 1062, 1063]
const LAST := 5487
var output := ""
var mode := ""
var rows: Array = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	output = OS.get_environment("SBTK_A06_DAMAGE_ROOT").replace("\\", "/")
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		quit(1)
		return
	mode = args[0]
	var profile := OS.get_environment("APPDATA").replace("\\", "/")
	if not _check(OS.has_feature("windows") and DisplayServer.get_name() == "headless"
			and output.is_absolute_path() and profile == output + "/profiles/" + mode + "/roaming"
			and ProjectSettings.globalize_path("user://").replace("\\", "/").begins_with(profile + "/"),
			"isolated Windows headless process"):
		_finish()
		return
	var input_path := output.path_join("objective-recording.json")
	if not _check(FileAccess.get_sha256(input_path) == PIN, "frozen approved objective input"):
		_finish()
		return
	var input: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(input_path))
	if not _check(_plain(input.request) == _plain(Product.REQUEST)
			and _plain(input.commands) == _plain([{"kind": "move", "tick": 0, "waypoint": 2}, {"kind": "move", "tick": 900, "waypoint": 3}])
			and input.max_ticks == LAST, "approved v1 seed 208 front and exactly two recorded commands"):
		_finish()
		return
	if mode == "control":
		_control(input)
	elif mode in ["resume-1061", "resume-1062", "resume-1063"]:
		_resume(input, int(mode.trim_prefix("resume-")))
	else:
		_check(false, "unsupported mode")
	_finish()

func _fresh(input: Dictionary) -> Dictionary:
	return Adapter._prepare_identity(Product.REQUEST.duplicate(true), input.operation_id)

func _slot(tick: int) -> String:
	return output.path_join("slots/first-damage-%d.save" % tick)

func _control(input: Dictionary) -> void:
	var fresh := _fresh(input)
	if not _check(fresh.ok, "approved product owner created"):
		return
	var owner: RefCounted = fresh.owner
	if not _check(owner.publish().ok, "fresh owner publishes C0"):
		owner.close()
		return
	var snapshots := {}
	var trace: Array = []
	var history: Array = []
	for tick in range(1, LAST + 1):
		if not _advance(owner, input):
			owner.close()
			return
		if tick in MARKS:
			var captured: Dictionary = owner.capture_checkpoint()
			if not _check(captured.ok and captured.packet.tick == tick and captured.packet.clock_ms == tick * 100,
					"capture first-damage boundary %d" % tick):
				owner.close()
				return
			if not _check(not FileAccess.file_exists(_slot(tick)) and Store.write(captured.packet, _slot(tick)).ok,
					"write new isolated slot %d" % tick):
				owner.close()
				return
			var raw := _raw(owner)
			snapshots[str(tick)] = {"raw": raw, "packet": captured.packet, "projection": owner.read_projection().projection,
				"slot_sha256": FileAccess.get_sha256(_slot(tick))}
			_check(raw.native.missiles.is_empty() and raw.native.swarms.is_empty(),
				"v1 boundary has no active legacy projectiles; no ST08 claim %d" % tick)
		var entry := _entry(owner)
		history.append_array(entry.events)
		if tick >= MARKS[0]:
			trace.append(entry)
		if tick in MARKS:
			snapshots[str(tick)].unread_events = entry.events
	var before: Dictionary = snapshots["1061"]
	var after: Dictionary = snapshots["1062"]
	var later: Dictionary = snapshots["1063"]
	var attacker_before := _fleet(before.raw, "RC-LIU-SQ-02")
	var attacker_after := _fleet(after.raw, "RC-LIU-SQ-02")
	var target_before := _fleet(before.raw, "RC-CAO-SQ-04")
	var target_after := _fleet(after.raw, "RC-CAO-SQ-04")
	var first_hits := history.filter(func(event): return event.kind == "salvo")
	_check(not first_hits.is_empty() and first_hits[0].tick == 1062 and first_hits[0].sq == 2
		and first_hits[0].other == 3 and first_hits[0].value.cat == "artillery"
		and first_hits[0].value.dmg == 638 and first_hits[0].value.hit, "first natural salvo matches archived 1062-tick damage oracle")
	_check(before.unread_events.is_empty() and later.unread_events.is_empty()
		and after.unread_events.size() == 2 and after.unread_events[0].kind == "salvo"
		and after.unread_events[1].kind == "ship_lost" and after.unread_events[1].value == 6,
		"first-damage event order is exactly salvo then six lost ships")
	_check(target_before.hull - target_after.hull == 638 and target_after.lost_ships - target_before.lost_ships == 6
		and _present(target_before) - _present(target_after) == 6 and target_before.stages != target_after.stages,
		"native hull, loss count and nonempty damage stages independently witness damage")
	_check(_conserved(target_before) and _conserved(target_after)
		and target_before.comp0 == target_after.comp0, "five damage stages conserve original per-type roster")
	_check(attacker_before.wch.artillery - attacker_after.wch.artillery == 1
		and attacker_after.next_fire.artillery > 1062, "native artillery charge and next-fire reservation change on the same commit")
	_check(not before.raw.native.contacts.is_empty() and before.raw.native.contacts.any(func(side): return not side.is_empty()),
		"active contact table is present at first-damage boundary")
	var final: Dictionary = owner.summary().summary
	_check(final.over and input.expected_settlement.keys().all(func(key): return final.settlement.get(key) == input.expected_settlement[key]),
		"uninterrupted approved v1 run reaches the recorded 5487-tick settlement")
	var oracle := {"format": "a06/v1-first-damage/1", "input_sha256": PIN,
		"pid": OS.get_process_id(), "snapshots": snapshots, "trace": trace, "terminal": final}
	_check(_write_new(output.path_join("oracle.bin"), var_to_bytes(oracle)), "retain typed native oracle and full suffix witnesses")
	_write_new(output.path_join("control-summary.json"), (JSON.stringify({
		"scope": "ST03/ST04 and supported ST14 at first damage; no active ST08 or general A06 claim",
		"pid": OS.get_process_id(), "marks": MARKS, "trace_count": trace.size(), "terminal": final,
		"target_before": _selected(target_before), "target_after": _selected(target_after),
		"attacker_before": _selected(attacker_before), "attacker_after": _selected(attacker_after)
	}, "  ", true, true) + "\n").to_utf8_buffer())
	owner.close()

func _resume(input: Dictionary, tick: int) -> void:
	var oracle_path := output.path_join("oracle.bin")
	var oracle_hash := FileAccess.get_sha256(oracle_path)
	var oracle: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(oracle_path))
	if not _check(oracle.format == "a06/v1-first-damage/1" and oracle.input_sha256 == PIN
			and oracle.pid != OS.get_process_id(), "read typed oracle produced by a different process"):
		return
	var reference: Dictionary = oracle.snapshots[str(tick)]
	var stored := Store.read(_slot(tick))
	if not _check(stored.ok and FileAccess.get_sha256(_slot(tick)) == reference.slot_sha256, "read exact original checkpoint bytes"):
		return
	if tick == 1062:
		_reject_bad_witness(input, stored.payload, reference.slot_sha256)
	var begun := Host.begin_restore(stored.payload, BattleBrief.new())
	if not _check(begun.ok and begun.brief.operation_request() == Product.REQUEST, "real host starts detached approved-v1 restore"):
		return
	var completed := _complete(begun.job)
	if not _check(completed.ok and completed.done, "budgeted detached replay completes state verification"):
		return
	var owner: RefCounted = completed.owner
	var preview: Dictionary = owner.preview_initial_frame()
	_check(preview.ok and preview.frame.phase == "resume" and preview.frame.tick == tick
		and preview.frame.clock_ms == tick * 100 and preview.frame.events.is_empty(), "detached resume frame publishes no events")
	_check(owner.advance().get("error") == "owner_not_published"
		and owner.capture_checkpoint().get("error") == "owner_not_published", "detached owner cannot run or capture before publication")
	if not _check(Host.validate_restored_owner(owner, begun.brief).ok, "actual host validates the detached resume frame"):
		return
	_check(owner.publish().frame == preview.frame and owner.publish().get("error") == "owner_already_published",
		"validated owner publishes exactly once")
	_check(Service._same(_raw(owner), reference.raw), "all typed native fields, contacts, policy, cursors and route witnesses match")
	_check(Service._same(owner.read_projection().projection, reference.projection), "restored side-zero projection matches")
	_check(_plain(owner.capture_checkpoint().packet) == _plain(reference.packet), "published checkpoint reconstructs complete saved packet")
	_check(Service._same(owner.drain_events().events, reference.unread_events)
		and owner.drain_events().events.is_empty(), "saved unread first-damage events drain exactly once")
	var suffix_ok := true
	var count := 0
	for target in range(tick + 1, LAST + 1):
		if not _advance(owner, input):
			suffix_ok = false
			break
		var entry := _entry(owner)
		var expected: Dictionary = oracle.trace[target - MARKS[0]]
		if not Service._same(entry, expected):
			print("A06_SUFFIX_DIVERGED ", target)
			suffix_ok = false
			break
		count += 1
	_check(suffix_ok and count == LAST - tick, "every published suffix tick matches native/projection digests and ordered events")
	_check(Service._same(owner.summary().summary, oracle.terminal), "same final v1 outcome and operation identity")
	_check(owner.advance().get("error") == "operation_terminal" and owner.drain_events().events.is_empty(),
		"terminal continuation cannot repeat events or effects")
	_check(FileAccess.get_sha256(_slot(tick)) == reference.slot_sha256
		and FileAccess.get_sha256(oracle_path) == oracle_hash, "restore and continuation preserve original slot and oracle")
	owner.close()

func _reject_bad_witness(input: Dictionary, packet: Dictionary, slot_hash: String) -> void:
	var fresh := _fresh(input)
	if not _check(fresh.ok and fresh.owner.publish().ok, "fresh live control for late damage-boundary refusal"):
		return
	var live: RefCounted = fresh.owner
	var before := _raw(live)
	var bad := packet.duplicate(true)
	bad.state_digest = "0".repeat(64)
	var begun := Host.begin_restore(bad, BattleBrief.new())
	if not _check(begun.ok, "bad state witness reaches detached validation"):
		live.close()
		return
	var rejected := _complete(begun.job)
	_check(not rejected.ok and not rejected.has("owner") and rejected.get("error") == "checkpoint_state_mismatch",
		"late first-damage witness mismatch exposes no candidate")
	_check(Service._same(_raw(live), before) and FileAccess.get_sha256(_slot(1062)) == slot_hash,
		"late rejection preserves active owner and original slot")
	live.close()

func _complete(job: RefCounted) -> Dictionary:
	var result: Dictionary = job.step(4000)
	while result.ok and not result.done:
		if result.has("owner"):
			job.cancel()
			return {"ok": false, "error": "premature_owner"}
		result = job.step(4000)
	return result

func _advance(owner: RefCounted, input: Dictionary) -> bool:
	var now: int = owner.summary().summary.tick
	for row: Dictionary in input.commands:
		if row.tick == now:
			var projection: Dictionary = owner.read_projection().projection
			var queued := Adapter.queue(owner, {"kind": "move", "side": 0,
				"ids": projection.squadrons.filter(func(fleet): return fleet.side == 0).map(func(fleet): return fleet.id),
				"point": projection.operation.route_points[int(row.waypoint)]})
			if not queued.ok:
				_check(false, "recorded command failed at %d: %s" % [now, queued])
				return false
	var result: Dictionary = owner.advance()
	if not result.ok or result.has("movement_error"):
		_check(false, "native advance failed at %d: %s" % [now, result])
		return false
	return true

func _raw(owner: RefCounted) -> Dictionary:
	var runtime: RefCounted = owner._runtime
	return {"native": runtime._sim.replay_witness(), "ledger": runtime._policy.ledger(),
		"reserve": runtime._reserve, "route_progress": runtime._progress, "stopped_since": runtime._stopped_since,
		"command_history": runtime._command_history, "pending": runtime._commands,
		"events": runtime._committed_events, "event_cursor": runtime._event_cursor,
		"proposal_serial": runtime._policy._proposal_id}.duplicate(true)

func _entry(owner: RefCounted) -> Dictionary:
	return {"tick": owner.summary().summary.tick, "native_sha256": _sha(var_to_bytes(_raw(owner))),
		"projection_sha256": _sha(var_to_bytes(owner.read_projection().projection)),
		"events": owner.drain_events().events}

func _fleet(raw: Dictionary, id: String) -> Dictionary:
	for fleet: Dictionary in raw.native.fleets:
		if fleet.sq_id == id:
			return fleet
	return {}

func _present(fleet: Dictionary) -> int:
	var count := 0
	for stage: Array in fleet.stages.values():
		count += int(stage[0]) + int(stage[1]) + int(stage[2])
	return count

func _conserved(fleet: Dictionary) -> bool:
	for kind: String in fleet.comp0:
		var stage: Array = fleet.stages[kind]
		if stage.size() != 5 or stage.any(func(value): return typeof(value) != TYPE_INT or value < 0):
			return false
		if stage.reduce(func(a, b): return a + b, 0) != fleet.comp0[kind]:
			return false
	return true

func _selected(fleet: Dictionary) -> Dictionary:
	var result := {}
	for key in ["sq_id", "comp0", "stages", "hull", "max_hull", "lost_ships", "ammo", "wch", "wmax",
			"next_fire", "energy_m", "energy_rem", "heat_m", "heat_rem"]:
		result[key] = fleet[key]
	return result

func _plain(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))

func _sha(bytes: PackedByteArray) -> String:
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(bytes)
	return digest.finish().hex_encode()

func _write_new(path: String, bytes: PackedByteArray) -> bool:
	if FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(bytes)
	file.flush()
	var ok := file.get_error() == OK
	file.close()
	return ok and FileAccess.get_file_as_bytes(path) == bytes

func _check(condition: bool, label: String) -> bool:
	rows.append({"pass": condition, "label": label})
	print("A06_DAMAGE_CHECK ", condition, " ", label)
	return condition

func _finish() -> void:
	var passed := rows.filter(func(row): return row.pass).size()
	_write_new(output.path_join(mode + "-matrix.json"), (JSON.stringify({
		"mode": mode, "pid": OS.get_process_id(), "checks": rows.size(), "passed": passed, "rows": rows
	}, "  ", true, true) + "\n").to_utf8_buffer())
	print("A06_FIRST_DAMAGE ", mode, " ", passed, "/", rows.size())
	quit(0 if passed == rows.size() else 1)
