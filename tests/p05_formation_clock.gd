extends SceneTree

const Adapter := preload("res://scripts/first_operation_adapter.gd")
const Codec := preload("res://scripts/first_operation_replay_codec.gd")
const Product := preload("res://scripts/first_operation_source_reference.gd")
const NativeTick := preload("res://core/battle/first_operation_native_tick.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var profile := OS.get_environment("SBTK_P05_TRANSITION_PROFILE")
	var expected := profile.path_join("Godot/app_userdata/SpaceBattleOfThreeKingdoms").replace("\\", "/").to_lower()
	if _check(not profile.is_empty() and OS.get_user_data_dir().replace("\\", "/").to_lower() == expected,
			"isolated profile"):
		_verify()
		_verify_persistence()
	print("P05_FORMATION_CLOCK checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _verify() -> void:
	var prepared := Adapter.prepare_fresh(Product.REQUEST)
	if not _check(prepared.ok, "prepare pinned Red Cliffs v1 product roster"):
		return
	var owner: RefCounted = prepared.owner
	if _check(owner.publish().ok, "publish owner"):
		_verify_owner(owner)
	owner.close()


func _verify_owner(owner: RefCounted) -> void:
	# Exercise the actual roster and the native combat timer in memory. The
	# operation owner rejects formation orders and is tested before this probe.
	var sim: NativeTick = owner._runtime._sim
	var fleets := sim.st.alive(0)
	var roster := {}
	for fleet: FleetState in fleets:
		roster[fleet.sq_id] = [fleet.ships, fleet.formation_id]
	if not _check(roster == {"RC-LIU-SQ-01": [39000, "FRM-03"], "RC-LIU-SQ-02": [21000, "FRM-01"]},
			"exact 39/21 starting rosters and formations"):
		return
	var initial: Dictionary = owner.capture_checkpoint()
	if not _check(initial.ok, "capture initial checkpoint"):
		return
	var initial_view: Dictionary = owner.read_projection()
	for fleet: FleetState in fleets:
		var target := "FRM-01" if fleet.formation_id == "FRM-03" else "FRM-03"
		var rejected := Adapter.queue(owner, _command(fleet, target))
		_check(rejected == {"ok": false, "error": "unsupported_dev_command", "path": "command.kind"},
			"%s public formation order rejected" % fleet.sq_id)
	_check(owner.capture_checkpoint() == initial and owner.read_projection() == initial_view,
		"rejected commands preserve checkpoint and public projection")
	_verify_round(sim, fleets)
	_verify_round(sim, fleets)


func _verify_persistence() -> void:
	var prepared := Adapter.prepare_fresh(Product.REQUEST)
	if not _check(prepared.ok, "prepare persistence control operation"):
		return
	var owner: RefCounted = prepared.owner
	if _check(owner.publish().ok, "publish persistence control operation"):
		_check_persistence(owner, prepared.operation_id)
	owner.close()


func _check_persistence(owner: RefCounted, operation_id: String) -> void:
	var withdraw := Adapter.queue(owner, {"kind": "withdraw", "side": 0})
	if not _check(withdraw.ok and Adapter.advance(owner).ok, "commit supported Withdraw"):
		return
	var finalize := Adapter.queue(owner, {"kind": "finalize_withdrawal", "side": 0})
	var saved: Dictionary = owner.capture_checkpoint()
	if not _check(finalize.ok and saved.ok, "capture one applied and one pending command"):
		return
	var packet: Dictionary = saved.packet
	var control := Adapter.begin_restore(packet)
	if not _check(control.ok, "unmodified checkpoint passes restore preflight"):
		return
	control.job.cancel()
	for pending in [true, false]:
		var changed := packet.duplicate(true)
		var batch: Array = changed.pending if pending else changed.commands[0].batch
		batch[0] = {"kind": "formation"}
		var expected := "packet.pending[0]" if pending else "packet.commands[0].batch[0]"
		var restore := Adapter.begin_restore(changed)
		_check(restore == {"ok": false, "error": "invalid_checkpoint_command", "path": expected},
			"formation is rejected at " + expected)
		if restore.ok:
			restore.job.cancel()
	_check(owner.capture_checkpoint() == saved, "restore rejects preserve the original owner")
	var terminal := Adapter.advance(owner)
	if not _check(terminal.ok and terminal.summary.over, "commit supported Finalize withdrawal"):
		return
	var record := Adapter.make_recording(Product.REQUEST, operation_id,
		[withdraw.record, finalize.record], terminal.summary.settlement)
	if not _check(record.ok and Adapter.run_replay(record.bundle).ok, "unmodified recording replays"):
		return
	var changed_record: Dictionary = record.bundle.duplicate(true)
	changed_record.commands[0].kind = "formation"
	var result := Adapter.open_replay(changed_record)
	var reject := {"ok": false, "error": "unsupported_operation_command", "path": "commands[0].kind"}
	_check(result == reject, "formation is rejected before replay opens")
	if result.ok:
		result.replay.close()
	var directory := ProjectSettings.globalize_path("user://p05-" + operation_id.get_file())
	if not _check(DirAccess.make_dir_absolute(directory) == OK, "create isolated replay fixture directory"):
		return
	var original := directory.path_join("original.pcopreplay")
	if not _check(Codec.write(record.bundle, original).ok and Codec.read(original).ok,
			"unmodified replay file writes and reads"):
		return
	var digest := FileAccess.get_sha256(original)
	var changed_path := directory.path_join("formation.pcopreplay")
	_check(Codec.write(changed_record, changed_path) == reject and not FileAccess.file_exists(changed_path),
		"formation recording cannot publish a replay file")
	var body := JSON.stringify(changed_record, "", true, true)
	var fixture := FileAccess.open(changed_path, FileAccess.WRITE)
	if not _check(fixture != null, "open separate replay mutation fixture"):
		return
	fixture.store_string(Codec._envelope(body, Codec._rules_and_inputs_digest()))
	fixture.close()
	_check(Codec.read(changed_path) == reject and FileAccess.get_sha256(original) == digest,
		"canonical replay with formation is rejected and original bytes remain intact")


func _verify_round(sim: NativeTick, fleets: Array) -> void:
	var tick := sim.st.tick
	var clock_ms := sim.st.clock_ms
	var ticks := BattleRules.ticks(5.0, sim.st.hz)
	var orders := {}
	for fleet: FleetState in fleets:
		var source := fleet.formation_id
		var target := "FRM-01" if source == "FRM-03" else "FRM-03"
		orders[fleet.id] = {"from": source, "to": target}
		sim.issue(_command(fleet, target))
	_check(_formation_events(sim, orders, "formation_start", tick), "both native orders begin at tick %d" % tick)
	var read := sim.projection(0)
	_check(_matches_projection(read, orders, 5.0) and sim.st.tick == tick and sim.st.clock_ms == clock_ms,
		"same-tick projection reads preserve the full 5s timer")
	var countdown_ok := true
	var no_early_events := true
	for elapsed in range(1, ticks):
		sim.advance_combat()
		countdown_ok = _matches_projection(sim.projection(0), orders, float(ticks - elapsed) / sim.st.hz) and countdown_ok
		for event: Dictionary in sim.drain_events():
			no_early_events = no_early_events and event.kind != "formation_changed"
	_check(countdown_ok and sim.st.tick == tick + ticks - 1, "both projections count down one tick at a time")
	_check(no_early_events, "no formation commit before the deadline")
	sim.advance_combat()
	_check(sim.st.tick == tick + ticks and sim.st.clock_ms == clock_ms + 5000
		and _matches_projection(sim.projection(0), orders, 0.0), "both formations commit at exactly 5,000ms")
	_check(_formation_events(sim, orders, "formation_changed", tick + ticks),
		"one native completion event per fleet at tick %d" % (tick + ticks))


func _command(fleet: FleetState, target: String) -> Dictionary:
	return BattleSim.command(0, [fleet.id], "formation", -1, Vector2.ZERO, {"id": target})


func _matches_projection(frame: Dictionary, orders: Dictionary, remaining: float) -> bool:
	var matched := 0
	for row: Dictionary in frame.squadrons:
		if not orders.has(row.id):
			continue
		var order: Dictionary = orders[row.id]
		var active := remaining > 0.0
		if row.formation_id != (order.from if active else order.to) or row.form_to != (order.to if active else ""):
			return false
		if not is_equal_approx(row.form_left_s, remaining):
			return false
		matched += 1
	return matched == orders.size()


func _formation_events(sim: NativeTick, orders: Dictionary, kind: String, tick: int) -> bool:
	var completed := {}
	for event: Dictionary in sim.drain_events():
		if event.kind == "rejected":
			return false
		if event.kind != kind:
			continue
		if not orders.has(event.sq) or completed.has(event.sq) or event.tick != tick or event.value != orders[event.sq].to:
			return false
		completed[event.sq] = true
	return completed.size() == orders.size()


func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
	print("P05_FORMATION_CLOCK_CHECK ", ok, " ", label)
	return ok
