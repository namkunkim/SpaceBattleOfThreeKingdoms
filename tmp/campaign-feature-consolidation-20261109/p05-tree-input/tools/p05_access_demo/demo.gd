extends Node2D

const Guard = preload("res://guard.gd")
const SCALE := 0.55
const ORIGIN := Vector2(48, 78)
const INK := Color("#e1efff")
const ROUTE_COLORS := {"EJAC": Color("#54e0c6"), "EJBDC": Color("#88aeff"), "RC": Color("#ffa96b")}

var manifest: Dictionary
var mode := "WindowsManual"
var evidence := ""
var results: Array[Dictionary] = []
var witnesses: Dictionary = {}
var failures := 0
var button: Button
var output: Label


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			mode = arg.trim_prefix("--mode=")
		if arg.begins_with("--evidence="):
			evidence = arg.trim_prefix("--evidence=")
	var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
	if not loaded is Dictionary or loaded.get("schema") != "p05-access-demo-v1" or loaded.get("envelope") != "p05-layout-disks-v1" or loaded.get("space") != "effective":
		push_error("P05 manifest not valid")
		get_tree().quit(2)
		return
	manifest = loaded
	button = Button.new()
	button.text = "Run P05 access checks"
	button.position = Vector2(48, 12)
	button.size = Vector2(220, 45)
	add_child(button)
	button.pressed.connect(_start_checks)
	output = Label.new()
	output.position = Vector2(290, 20)
	output.text = "P05 isolated native route validation"
	add_child(output)
	queue_redraw()
	if mode in ["Headless", "WindowsAuto"]:
		button.pressed.emit.call_deferred()


func _record(label: String, ok: bool, extra: Dictionary = {}) -> void:
	var result := {"case": label, "pass": ok}
	result.merge(extra)
	results.append(result)
	if not ok:
		failures += 1


func _summary(g: Guard) -> Dictionary:
	var state := g.snapshot()
	var point: Vector2 = state.plan
	var centers := []
	for p: Vector2 in state.positions:
		centers.append([p.x, p.y])
	return {"plan": [point.x, point.y], "centers": centers,
		"heading_deg": rad_to_deg(state.heading), "tick": state.tick, "route_index": state.index,
		"returning": state.returning, "moving": state.moving, "visits": state.visits,
		"complete": state.complete}


func _snapshot(g: Guard) -> Dictionary:
	return {"state": g.snapshot(), "route": g.route_id, "points": g.points.duplicate(),
		"offsets": g.offsets.duplicate(), "radii": g.radii.duplicate(),
		"neck": g.neck, "bad_service": g.inaccessible_service}


func _transaction(g: Guard, before: Dictionary) -> Dictionary:
	var after := _snapshot(g)
	return {"unchanged": after == before, "before": before, "after": after}


func _advance(g: Guard, index: int) -> String:
	var remaining := 6000
	while g.state.index < index and remaining > 0:
		var problem := g.step()
		if problem != "":
			return problem
		remaining -= 1
	return "" if g.state.index == index else "step_limit"


func _positive(id: String) -> void:
	var g := Guard.new(manifest)
	var problem := g.start(id)
	_record(id + "_entry", problem == "", {"reason": problem})
	if problem != "":
		return
	if id != "RC":
		problem = _advance(g, 2)
		if problem == "":
			problem = g.visit("service")
		_record(id + "_service_stop", problem == "", {"reason": problem, "state": _summary(g)})
		if problem != "":
			return
		var stop: Vector2 = g.state.plan
		problem = _advance(g, 3)
		_record(id + "_service_departure", problem == "" and g.state.plan != stop, {"reason": problem})
		if problem != "":
			return
	problem = _advance(g, g.points.size() - 1)
	if problem == "":
		problem = g.visit("goal")
	_record(id + "_goal_access", problem == "", {"reason": problem, "state": _summary(g)})
	if problem != "":
		return
	witnesses[id] = g.snapshot()
	if id != "RC":
		problem = g.return_to_e()
		if problem == "":
			problem = _advance(g, g.points.size() - 1)
		if problem == "":
			problem = g.visit("exit")
		_record(id + "_explicit_return_exit", problem == "" and g.state.complete,
			{"reason": problem, "state": _summary(g)})


func _negative() -> void:
	var g := Guard.new(manifest)
	g.start("EJAC")
	var prior := _snapshot(g)
	var problem := g.step([Vector2.ZERO, Vector2(1.5, 1.5)])
	_record("tracking_rejection_preserves_entire_group", problem == "tracking_budget" and _snapshot(g) == prior,
		{"reason": problem, "transaction": _transaction(g, prior)})
	var forward := g.points[0].direction_to(g.points[1])
	problem = g.step([Vector2.ZERO, forward])
	_record("speed_rejection_preserves_entire_group", problem == "step_speed" and _snapshot(g) == prior,
		{"reason": problem, "transaction": _transaction(g, prior)})
	problem = g.step()
	_record("tracking_valid_retry", problem == "" and g.state.tick == prior.state.tick + 1 and g.state.positions != prior.state.positions,
		{"reason": problem, "state": _summary(g)})
	g.start("EJAC", true)
	for _i in 6000:
		prior = _snapshot(g)
		problem = g.step()
		if problem != "":
			break
	_record("physical_throat_rejects_sweep", problem == "throat_clearance" and _snapshot(g) == prior,
		{"reason": problem, "transaction": _transaction(g, prior)})
	g.start("EJAC", false, true)
	problem = _advance(g, 2)
	prior = _snapshot(g)
	if problem == "":
		problem = g.visit("service")
	_record("active_service_outside_legal_center_preserves_state", problem == "service_inaccessible" and _snapshot(g) == prior,
		{"reason": problem, "transaction": _transaction(g, prior)})
	var old_index: int = g.state.index
	problem = _advance(g, old_index + 1)
	_record("inaccessible_service_route_still_open", problem == "" and g.state.index == old_index + 1, {"reason": problem})
	prior = _snapshot(g)
	problem = g.start("INVALID")
	_record("invalid_start_preserves_active_route", problem == "unknown_route" and _snapshot(g) == prior,
		{"reason": problem, "transaction": _transaction(g, prior)})


func _start_checks() -> void:
	button.disabled = true
	results.clear()
	witnesses.clear()
	failures = 0
	for id in ["EJAC", "EJBDC", "RC"]:
		_positive(id)
	_negative()
	output.text = "%d/%d checks passed  |  isolated P05" % [results.size() - failures, results.size()]
	queue_redraw()
	var display := DisplayServer.get_name()
	var info := {"schema": manifest.schema, "mode": mode, "os": OS.get_name(), "display": display,
		"godot": Engine.get_version_info(), "device": RenderingServer.get_video_adapter_name(),
		"window": str(DisplayServer.window_get_size()), "results": results}
	if mode != "Headless":
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var frame := get_viewport().get_texture().get_image()
		var nonuniform := not frame.is_empty() and frame.get_pixel(5, 5) != frame.get_pixel(80, 33)
		var png_result := ERR_INVALID_PARAMETER
		if nonuniform and not evidence.is_empty():
			png_result = frame.save_png(evidence.path_join("P05-Windows-frame.png"))
		info["frame"] = {"completed": true, "nonuniform": nonuniform, "save_result": png_result,
			"width": frame.get_width(), "height": frame.get_height()}
		if mode == "WindowsAuto" and (OS.get_name() != "Windows" or display == "headless" or png_result != OK):
			failures += 1
	info["failures"] = failures
	var encoded := JSON.stringify(info)
	print("P05_RESULT " + encoded)
	if not evidence.is_empty():
		var file := FileAccess.open(evidence.path_join(mode + ".json"), FileAccess.WRITE)
		if file == null:
			failures += 1
		else:
			file.store_string(JSON.stringify(info, "  ") + "\n")
	if mode == "WindowsManual":
		button.disabled = false
	else:
		get_tree().quit(0 if failures == 0 else 1)


func _map_point(p: Vector2) -> Vector2:
	return ORIGIN + p * SCALE


func _draw() -> void:
	if manifest.is_empty():
		return
	var map := Rect2(ORIGIN, Guard.vec(manifest.world) * SCALE)
	draw_rect(map, Color("#152338"))
	draw_rect(map, Color("#3a526b"), false, 2.0)
	for id in ROUTE_COLORS:
		var path := PackedVector2Array()
		for p in manifest.witness[id].points:
			path.append(_map_point(Guard.vec(p)))
		draw_polyline(path, ROUTE_COLORS[id], 3.0, true)
	for id in manifest.nodes:
		var p := _map_point(Guard.vec(manifest.nodes[id]))
		draw_circle(p, 6.0, INK)
		draw_string(ThemeDB.fallback_font, p + Vector2(9, -8), id, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, INK)
	for id in witnesses:
		var indexes := ["RC-CAO-SQ-05"] if id == "RC" else ["RC-LIU-SQ-01", "RC-LIU-SQ-02"]
		for i in indexes.size():
			var p := _map_point(witnesses[id].positions[i])
			var radius := (float(manifest.radii[indexes[i]]) + Guard.TRACK + Guard.SAFETY) * SCALE
			draw_circle(p, radius, Color(ROUTE_COLORS[id], 0.20))
			draw_arc(p, radius, 0, TAU, 48, ROUTE_COLORS[id], 1.5, true)
	draw_string(ThemeDB.fallback_font, Vector2(48, 738),
		"Teal  front route     Blue  detour     Orange  reinforcements     Circles  stopped goal-access witnesses",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17, INK)
