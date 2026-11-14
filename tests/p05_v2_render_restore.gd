extends SceneTree

const Host := preload("res://scripts/first_operation_host.gd")
const Owner := preload("res://scripts/first_operation_v2_owner.gd")
const Codec := preload("res://scripts/first_operation_v2_record_codec.gd")
const Restore := preload("res://scripts/first_operation_v2_restore.gd")
const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check(Checkpoint.rules_digest() == "b7189ae8f3408fd4e053a792491ac5f6457a520218df2b709c4a8e3986863658",
		"v1 core digest unchanged")
	var brief := BattleBrief.new()
	brief.select_first_operation_v2()
	var active := _install(Owner.prepare_fresh().owner, brief, false)
	if active == null:
		quit(1)
		return
	var restored_hosts := []
	var matches := true
	var chords_clear := true
	active.started = true
	for sample in range(1, 154):
		active._process(1.0 / 30.0)
		if sample == 3:
			_check(active.operation_owner.queue(Owner.FORMATION).ok, "original native formation queued")
		if sample in [3, 6, 66, 150, 153]:
			var restored := _restore(active, brief)
			if restored != null:
				_check(_same_pose(active, restored), "restored exact pose at sample %d" % sample)
				restored_hosts.append({"host": restored, "sample": sample})
		for pair in restored_hosts:
			if sample <= pair.sample:
				continue
			var candidate: Node = pair.host
			var before := _positions(candidate)
			candidate._process(1.0 / 30.0)
			var candidate_vis := _vis(candidate)
			chords_clear = chords_clear and candidate_vis.p05.clear(before, _positions(candidate), 0.0)
			matches = matches and _same_pose(active, candidate)
	_check(matches, "uninterrupted and restored positions agree through completion")
	_check(chords_clear, "all adjacent restored slot positions retain swept clearance")
	for pair in restored_hosts:
		var host: Node = pair.host
		_check(host.frame.tick == 51 and _vis(host).p05_time == 145.0 / 30.0,
			"restored run reaches certified endpoints and tick 51")
		host.free()
	active.free()
	print("P05_V2_RENDER_RESTORE %d/%d" % [checks - failures, checks])
	quit(0 if failures == 0 and restored_hosts.size() == 5 else 1)


func _install(owner: RefCounted, brief: BattleBrief, restored: bool) -> Node:
	var v1 := BattleBrief.new()
	v1.select_first_operation_product()
	root.get_node("WorldLink").brief = v1
	var host := Host.new()
	root.add_child(host)
	_check(host._formation_renderer == null, "v1 default marker route unchanged")
	if not _check(host._publish_candidate(owner, brief, restored).ok
			and host.enable_certified_formation_presentation(), "certified v2 presentation installed"):
		host.free()
		return null
	return host


func _restore(active: Node, brief: BattleBrief) -> Node:
	var captured: Dictionary = active.operation_owner.capture_record()
	var bytes := Codec.encode(captured.record, Codec.SAVE_FORMAT)
	var begun := Restore.begin_restore(bytes.bytes)
	if not _check(begun.ok, "begin verified restore"):
		return null
	for i in 100:
		var status: Dictionary = begun.job.step(4000)
		if not status.ok:
			_check(false, "restore failed: %s" % status)
			return null
		if status.done:
			var host := _install(status.owner, brief, true)
			if host != null:
				host.started = true
			return host
	begun.job.cancel()
	_check(false, "restore budget exhausted")
	return null


func _vis(host: Node) -> FleetRenderer.FleetVis:
	var row: Dictionary = host._formation_source.squadrons()[0]
	return host._formation_renderer.vis[row.id]


func _positions(host: Node) -> Dictionary:
	var vis := _vis(host)
	var row: Dictionary = host._formation_source.squadrons()[0]
	var center: Vector3 = host._formation_source.to3(row.pos)
	var unrotate := Basis(Vector3.UP, row.heading + PI * 0.5)
	var result := {}
	for i in vis.slots.size():
		var slot: FleetRenderer.Slot = vis.slots[i]
		var point := unrotate * (slot.pos - center) / CameraRig.S
		result[vis.p05.rows[i].id] = Vector2(-point.z, point.x)
	return result


func _same_pose(a: Node, b: Node) -> bool:
	var one := _vis(a)
	var two := _vis(b)
	return a.frame.tick == b.frame.tick and one.p05_time == two.p05_time \
		and _positions(a) == _positions(b)


func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
	print("P05_V2_RENDER_RESTORE_CHECK ", ok, " ", label)
	return ok
