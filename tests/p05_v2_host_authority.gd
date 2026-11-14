extends SceneTree

const Host := preload("res://scripts/first_operation_host.gd")
const Owner := preload("res://scripts/first_operation_v2_owner.gd")
const Adapter := preload("res://scripts/first_operation_adapter.gd")
const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")

var failures := 0
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var profile := OS.get_environment("APPDATA").replace("\\", "/")
	if not _check(not profile.is_empty() and ProjectSettings.globalize_path("user://").replace("\\", "/").begins_with(profile + "/"),
			"isolated profile"):
		quit(1)
		return
	_check(Checkpoint.rules_digest() == "b7189ae8f3408fd4e053a792491ac5f6457a520218df2b709c4a8e3986863658",
		"v1 rules digest unchanged")
	var link := root.get_node("WorldLink")
	var v1 := BattleBrief.new()
	v1.select_first_operation_product()
	link.brief = v1
	var host := Host.new()
	root.add_child(host)
	_check(not host.enable_certified_formation_presentation(), "v1 owner and brief rejected")
	_check(not host.operation_owner.queue(Owner.FORMATION).ok, "v1 still rejects native formation")
	_check(host.read_saved_battle(true).get("ok") == false, "isolated v1 slot starts empty")

	var v2 := BattleBrief.new()
	v2.select_first_operation_v2()
	_check(not Adapter.prepare_fresh(v2.operation_request()).ok, "v1 preparation does not admit v2")
	var prepared := Owner.prepare_fresh()
	if not _check(prepared.ok and host._publish_candidate(prepared.owner, v2, false).ok, "publish actual internal v2 owner"):
		host.free()
		quit(1)
		return
	var id: String = prepared.owner.presentation_identity()
	_check(id.begins_with(Owner.ID_PREFIX) and not id.is_empty(), "runtime-owned v2 identity")
	_check(not prepared.owner.capture_checkpoint().ok, "v2 cannot emit v1 checkpoint")
	host.frame.meta.operation_id = "forged"
	_check(not host.enable_certified_formation_presentation(), "mismatching frame identity rejected")
	host.frame.meta.operation_id = id
	host.brief = v1
	_check(not host.enable_certified_formation_presentation(), "internal v2 owner plus v1 brief rejected")
	host.brief = v2
	if not _check(host.enable_certified_formation_presentation(), "matching v2 owner, brief and frame activate"):
		host.free()
		quit(1)
		return
	_check(not host.enable_certified_formation_presentation(), "duplicate activation refused")
	var id_on_wire: String = host._formation_source.squadrons()[0].operation_id
	_check(id_on_wire == id, "committed renderer row uses runtime identity")
	_check(not prepared.owner.queue(Owner.FORMATION).ok, "formation requires an established stationary tick")
	host.started = true
	var reached := -1
	var logical := -1
	var safe := true
	for sample in range(1, 154):
		host._process(1.0 / 30.0)
		if sample == 3:
			safe = safe and _check(host.frame.tick == 1 and prepared.owner.queue(Owner.FORMATION).ok, "enqueue certified 39-ship formation")
			_check(not prepared.owner.queue(Owner.FORMATION).ok, "duplicate formation refused")
		var row: Dictionary = host._formation_source.squadrons()[0]
		var vis: FleetRenderer.FleetVis = host._formation_renderer.vis[row.id]
		if vis.p05 == null:
			safe = false
			break
		safe = safe and row.operation_id == id and row.tick == host.frame.tick
		if reached < 0 and is_equal_approx(vis.p05_time, 145.0 / 30.0):
			reached = sample
		if logical < 0 and row.formation_id == Owner.FORMATION.formation_id and row.form_to == "":
			logical = sample
	print("P05_V2_HOST_TIMING ", reached, " ", logical)
	_check(safe and reached == 152 and logical == 153, "host update preserves authority and 50-tick formation interval")
	var fresh := Adapter.prepare_fresh(v1.operation_request())
	_check(fresh.ok and host._publish_candidate(fresh.owner, v1, false).ok, "replacement publishes v1 through normal path")
	_check(host._formation_renderer == null and not host.enable_certified_formation_presentation()
		and prepared.owner.presentation_identity().is_empty(), "replacement clears renderer and closes v2 authority")
	host.free()
	print("P05_V2_HOST_AUTHORITY %d/%d" % [checks - failures, checks])
	quit(0 if failures == 0 else 1)


func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
	print("P05_V2_HOST_CHECK ", condition, " ", label)
	return condition
