extends SceneTree

const Ops := preload("res://scripts/restricted_operation_checkpoint.gd")
const Service := preload("res://core/battle/operation_service_state.gd")
const RUN_PREFIX := "a06-mixed-suffix"

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_probe()
	print("A06 restricted mixed suffix: %d/%d" % [checks - failures, checks])
	quit(0 if failures == 0 and checks == 18 else 1)


func _probe() -> void:
	# Keep the existing restricted checkpoint fixture and applied/queued prefix.
	var profile := {"profile_id": "operating-checkpoint-poc", "rules": PocSetup.profile().rules,
		"ally": [{"name":"A","role":"A","ships":30,"lv":1,"x":500,"y":500,"p":0,"flag":true}],
		"foe": [{"name":"B","role":"B","ships":30,"lv":1,"x":750,"y":500,"p":0,"flag":true}], "reinf":[]}
	var input := {"mode":"operation","format":"p02/restricted-headless/1","profile":profile,
		"seed":20824,"hz":10,"initial_controls":[],"policy":"none","max_ticks":1000}
	var user_dir := DirAccess.open("user://")
	var run_name := "%s-%d-%d" % [RUN_PREFIX, OS.get_process_id(), Time.get_ticks_usec()]
	# A private directory is claimed once and retained with the slot for review.
	if not expect(user_dir != null and user_dir.make_dir(run_name) == OK, "claim private evidence directory"):
		return
	var slot := "user://%s/checkpoint.pcopstate" % run_name
	print("A06 retained slot: ", ProjectSettings.globalize_path(slot))

	var made := Ops.create(input)
	if not expect(made.ok, "create restricted operation: %s" % made.get("error", "")):
		return
	var session: RefCounted = made.session
	_compare_suffix(session, slot)
	session.close()


func _compare_suffix(session: RefCounted, slot: String) -> void:
	var missile := BattleSim.command(0, [1], "missile", 2)
	var fighter := BattleSim.command(1, [2], "fighter", 1)
	var stop_ally := BattleSim.command(0, [1], "stop")
	var stop_foe := BattleSim.command(1, [2], "stop")
	var mixed := [{"seq": 3, "command": stop_ally}, {"seq": 4, "command": stop_foe}]
	var bad_after_valid := mixed + [{"seq": 6, "command": stop_ally}]
	if not expect(session.issue(1, missile).ok and session.issue(2, fighter).ok and session.advance().ok,
			"apply prefix through first 100 ms"):
		return
	if not expect(session.queue(3, stop_ally).ok, "queue sequence 3 before save"):
		return
	var saved: Dictionary = session.observe()
	if not expect(saved.ok and saved.state.tick == 1 and saved.state.clock_ms == 100 and
			saved.sim.command_log.size() == 2 and saved.sim._queue.size() == 1 and
			not saved.missiles.is_empty() and not saved.swarms.is_empty(), "saved prefix, clock and active projectiles"):
		return
	if not expect(session.write_checkpoint(slot).ok, "write restricted slot"):
		return
	var hash := FileAccess.get_sha256(slot)
	if not expect(not hash.is_empty(), "pin saved slot bytes"):
		return

	# An uninterrupted control establishes the ordinary append/apply behavior.
	if not expect(session.queue(4, stop_foe).ok, "control appends distinct sequence 4"):
		return
	var control_queued: Dictionary = session.observe()
	if not expect(control_queued.ok and control_queued.state.clock_ms == 100 and
			control_queued.sim.command_log.size() == 2 and
			control_queued.sim._queue.size() == 2 and
			int(control_queued.sim._queue[0].side) == 0 and int(control_queued.sim._queue[1].side) == 1,
			"control queue has two distinct commands in order"):
		return
	if not expect(session.advance().ok, "advance uninterrupted control once"):
		return
	var control: Dictionary = session.observe()
	if not expect(control.ok and control.state.tick == 2 and control.state.clock_ms == 200 and
			control.sim.command_log.size() == 4 and control.sim._queue.is_empty() and
			int(control.sim.command_log[2].side) == 0 and int(control.sim.command_log[3].side) == 1,
			"control applies each command once in order"):
		return

	var malformed: Dictionary = session.restore_checkpoint(slot, bad_after_valid)
	expect(malformed.get("error") == "invalid_checkpoint_suffix" and malformed.get("path") == "suffix",
		"reject later gap after validating overlap and adding sequence 4: %s" % malformed)
	expect(Service._same(session.observe(), control) and FileAccess.get_sha256(slot) == hash,
		"failed restore leaves live state, effects and saved slot unchanged")

	var restored: Dictionary = session.restore_checkpoint(slot, mixed)
	if not expect(restored.ok, "restore valid overlap followed by a new command: %s" % restored):
		return
	var restored_queue: Dictionary = session.observe()
	expect(Service._same(restored_queue, control_queued),
		"restored clock, projectiles, queue, derived view and pending events match control")
	if not expect(session.advance().ok, "advance restored runtime once"):
		return
	expect(Service._same(session.observe(), control), "restored ordered applied log and complete observed state match control")
	expect(FileAccess.get_sha256(slot) == hash, "successful restore leaves original slot bytes unchanged")


func expect(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)
	return ok
