extends Node3D

const RESTORE_BUDGET_USEC := 4000
const PRODUCT_SLOT_PATH := "user://pc-first-operation-product-v1.save"
const EXTERNAL_SAVE := "res://scripts/first_operation_external_save.gd"
const Product := preload("res://scripts/first_operation_source_reference.gd")
const Adapter := preload("res://scripts/first_operation_adapter.gd")
const SaveStore := preload("res://scripts/first_operation_save_store.gd")
const Settlements := preload("res://scripts/first_operation_settlement_store.gd")
const ReplayCodec := preload("res://scripts/first_operation_replay_codec.gd")
const OperationTrace := preload("res://scripts/first_operation_trace.gd")
const FormationOwner := preload("res://scripts/first_operation_v2_owner.gd")
const FormationSource := preload("res://view/fleet_render/first_operation_formation_source.gd")

var operation_owner: RefCounted
var frame := {}
var failure := {}
var settlement: BattleOutcome
var brief: BattleBrief
var link: Node
var started := false
var _returning := false
var _product_settlement_committed := false
var _clock := TickClock.new()
var _world := Vector2.ZERO
var _markers := {}
var _commands: Array[Button] = []
var _panel: VBoxContainer
var _status: Label
var _time: Label
var _sites: Label
var _save_status: Label
var _return: Button
var _start: Button
var _save: Button
var _load: Button
var _export: Button
var _import: Button
var _file_dialog: FileDialog
var _file_processing := false
var _field: Node3D
var _restore_job: RefCounted
var _restore_processing := false
var _restore_buttons := {}
var _cancel_restore: Button
var _replay_commands: Array = []
var _replay_recording := {}
var _can_record_replay := true
var _export_replay: Button
var _trace: OperationTrace
var _formation_source: FormationSource
var _formation_renderer: FleetRenderer

func _ready() -> void:
	set_process(false)
	link = get_node("/root/WorldLink")
	brief = link.brief
	_build_panel()
	_start = _button("Start operation", _begin)
	_start.name = "StartOperation"
	_panel.move_child(_start, 3)
	_start.hide()
	var candidate: RefCounted = link.take_prepared_restore()
	var restored := candidate != null
	if not restored:
		var prepared: Dictionary = Adapter.prepare_fresh(brief.operation_request())
		if not prepared.ok:
			_fail(prepared)
			return
		candidate = prepared.owner
	var result := _publish_candidate(candidate, brief, restored)
	if not result.ok:
		_fail(result)

static func product_save_supported() -> bool:
	return OS.has_feature("windows")


static func read_saved_battle(product := false) -> Dictionary:
	var path := PRODUCT_SLOT_PATH if product else SaveStore.SLOT_PATH
	var saved := SaveStore.read(path)
	if not saved.ok:
		return saved
	var request: Variant = saved.payload.get("request")
	var capability: String = Product.CAPABILITY if product else BattleBrief.FIRST_OPERATION_DEV_REQUEST.capability
	if not request is Dictionary or request.get("capability") != capability:
		return {"ok": false, "error": "checkpoint_slot_mismatch", "path": path}
	if product and saved.payload.get("operation_id") is String:
		var status := Settlements.product_settlement_status(saved.payload.operation_id)
		if not status.ok:
			return status
		if status.settled:
			return {"ok": false, "error": "checkpoint_already_settled", "path": path}
	return saved


func _is_product() -> bool:
	return brief.operation_request().get("capability") == Product.CAPABILITY

static func external_save_dialog(exporting: bool) -> FileDialog:
	var dialog := FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = false
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if exporting else FileDialog.FILE_MODE_OPEN_FILE
	dialog.title = "Export battle" if exporting else "Import battle"
	dialog.filters = PackedStringArray(["*.pcopsave ; Space Battle save"])
	if exporting:
		dialog.current_file = "battle.pcopsave"
	return dialog

static func read_external_battle(path: String, product := false) -> Dictionary:
	var codec := _external_save_codec()
	if codec == null:
		return {"ok": false, "error": "external_save_unavailable", "path": "codec"}
	return codec.read(path, product)

static func _external_save_codec() -> Script:
	if not ResourceLoader.exists(EXTERNAL_SAVE):
		return null
	var codec := load(EXTERNAL_SAVE) as Script
	return codec if codec != null and codec.can_instantiate() else null

static func error_text(problem: Dictionary) -> String:
	return "%s / %s" % [problem.get("error", "operation_failed"), problem.get("path", "runtime")]

static func begin_restore(packet: Dictionary, base: BattleBrief) -> Dictionary:
	var request: Variant = packet.get("request")
	if not request is Dictionary or request.get("route_id") not in ["front", "flank"]:
		return {"ok": false, "error": "invalid_operation_request", "path": "packet.request"}
	var target := BattleBrief.from_dict(base.to_dict())
	if request.get("capability") == Product.CAPABILITY:
		target.select_first_operation_product()
	else:
		target.select_first_operation_dev(request.route_id)
	var result: Dictionary = Adapter.begin_restore(packet)
	if not result.ok:
		return result
	return {"ok": true, "job": result.job, "brief": target}

static func validate_restored_owner(candidate: RefCounted, target: BattleBrief) -> Dictionary:
	var preview: Dictionary = candidate.preview_initial_frame()
	if not preview.ok or not _valid_candidate(preview.get("frame", {}), target, true):
		candidate.close()
		return {"ok": false, "error": "invalid_host_restore_frame", "path": "frame"}
	return {"ok": true}

static func restore_progress(tick: int, total: int) -> String:
	return "Restoring battle: %d / %d ticks" % [tick, total]

func _publish_candidate(candidate: RefCounted, target: BattleBrief, restored: bool) -> Dictionary:
	var preview: Dictionary = candidate.preview_initial_frame()
	if not preview.ok or not _valid_candidate(preview.get("frame", {}), target, restored):
		candidate.close()
		return {"ok": false, "error": "invalid_host_initial_frame", "path": "frame"}
	var published: Dictionary = candidate.publish()
	if not published.ok or published.get("frame") != preview.frame:
		candidate.close()
		return published if not published.ok else {"ok": false, "error": "initial_frame_changed", "path": "frame"}

	var previous := operation_owner
	if _trace != null:
		_trace.close(frame, "replaced")
		_trace = null
	_stop()
	operation_owner = candidate
	brief = target
	if link != null:
		link.brief = target
	started = false
	failure = {}
	settlement = null
	_product_settlement_committed = false
	_reset_replay_recording(candidate, restored)
	_world = preview.frame.meta.world_size
	_clock = TickClock.new()
	_clock.hz = preview.frame.hz
	_reset_field(preview.frame.projection.operation.route_points)
	_install_frame(published.frame)
	if _is_product() and OS.get_cmdline_user_args().has(OperationTrace.ARG):
		_trace = OperationTrace.new()
		_trace.start(brief.operation_request(), frame, restored)
	_start.text = "Resume operation" if restored else "Start operation"
	_start.show()
	var product := _is_product()
	_load.disabled = not restored or (product and not product_save_supported())
	_import.disabled = not restored or (product and not product_save_supported())
	_save_status.text = "Restored at tick %d" % frame.tick if restored else ""
	if previous != null:
		previous.close()
	return {"ok": true}

static func _valid_candidate(initial: Dictionary, target: BattleBrief, restored: bool) -> bool:
	var projection: Dictionary = initial.get("projection", {})
	var meta: Dictionary = initial.get("meta", {})
	if meta.get("capability") != target.operation_request().get("capability"):
		return false
	var extent: Variant = meta.get("world_size")
	if typeof(initial.get("tick")) != TYPE_INT or initial.tick < 0 \
			or typeof(initial.get("clock_ms")) != TYPE_INT or initial.clock_ms < 0:
		return false
	if initial.get("phase") != ("resume" if restored else "brief"):
		return false
	if not restored and (initial.tick != 0 or initial.clock_ms != 0):
		return false
	return initial.get("events") is Array and typeof(initial.get("hz")) == TYPE_INT and initial.hz > 0 \
		and projection.get("hz") == initial.hz and projection.get("tick") == initial.tick \
		and initial.clock_ms == initial.tick * roundi(1000.0 / initial.hz) \
		and extent is Vector2 and extent.is_finite() and extent.x > 0 and extent.y > 0 \
		and _valid_projection(projection, target) and projection.operation.settlement.is_empty() \
		and projection.squadrons.any(func(row): return row.side == 0)

static func _valid_projection(projection: Dictionary, target: BattleBrief) -> bool:
	var operation: Variant = projection.get("operation")
	if not operation is Dictionary or operation.get("route_id") != target.operation_route() \
			or not operation.get("settlement") is Dictionary or not operation.get("route_points") is Array \
			or operation.route_points.size() < 2 or not operation.get("sites") is Dictionary \
			or not projection.get("squadrons") is Array:
		return false
	for site in ["A", "B", "C"]:
		var state: Variant = operation.sites.get(site)
		if not state is Dictionary or not state.get("control") is String or not state.get("active") is bool:
			return false
	for point in operation.route_points:
		if not point is Vector2 or not point.is_finite():
			return false
	for row in projection.squadrons:
		if not row is Dictionary or typeof(row.get("id")) != TYPE_INT or typeof(row.get("side")) != TYPE_INT \
				or not row.get("pos") is Vector2 or not row.pos.is_finite():
			return false
	return true

func _begin() -> void:
	if operation_owner == null or started or not failure.is_empty():
		return
	started = true
	if _trace != null:
		_trace.write(frame, "operation_started")
	_start.hide()
	var product := _is_product()
	_save.disabled = product and not product_save_supported()
	_load.disabled = _save.disabled
	_export.disabled = _save.disabled
	_import.disabled = _save.disabled
	for button in _commands:
		button.disabled = false
	set_process(true)

func _process(delta: float) -> void:
	for i in _clock.advance(delta):
		if not step_operation():
			break
	if _formation_renderer != null:
		_formation_renderer.update(delta)

func step_operation() -> bool:
	if not started or _returning or _restore_job != null or _file_dialog != null or settlement != null or not failure.is_empty():
		return false
	var advanced: Dictionary = Adapter.advance(operation_owner)
	if not advanced.ok:
		_fail(advanced)
		return false
	var current: Dictionary = advanced.summary
	var projection: Dictionary = advanced.frame.projection
	if current.get("tick") != frame.tick + 1 or current.get("clock_ms") != frame.clock_ms + roundi(1000.0 / _clock.hz) \
			or projection.get("tick") != current.tick or not _valid_projection(projection, brief) \
			or not current.get("settlement") is Dictionary or projection.operation.settlement != current.settlement \
			or current.get("over") != (not current.settlement.is_empty()):
		_fail({"error": "invalid_host_tick", "path": "runtime.frame"})
		return false
	if current.over:
		settlement = BattleOutcome.from_operation(current.settlement, brief, current.clock_ms)
		if settlement == null:
			_fail({"error": "invalid_operation_settlement", "path": "runtime.summary.settlement"})
			return false
	_install_frame(advanced.frame)
	if _trace != null:
		_trace.record_frame(frame)
		if advanced.has("movement_error"):
			_trace.write(frame, "movement_error", {"error": advanced.movement_error})
		if settlement != null:
			_trace.write(frame, "operation_end", {"settlement": current.settlement})
			_trace.close(frame, "settled")
	if advanced.has("movement_error"):
		_status.text = str(advanced.movement_error)
	if settlement != null:
		_status.text = "%s / %s" % [settlement.kind, settlement.reason]
		if _can_record_replay:
			var recorded: Dictionary = Adapter.make_recording(
				brief.operation_request(), current.settlement.operation_id, _replay_commands, current.settlement)
			if recorded.ok:
				_replay_recording = recorded.bundle
				_export_replay.show()
			else:
				_save_status.text = error_text(recorded)
		_stop()
		return false
	return true

func _issue(kind: String, point := Vector2.ZERO) -> void:
	if not started or _returning or _restore_job != null or _file_dialog != null or settlement != null or not failure.is_empty():
		return
	var ids := []
	for row in frame.projection.squadrons:
		if row.side == 0 and not row.get("dead", false) and not row.get("out", ""):
			ids.append(row.id)
	var command := {"side": 0, "kind": kind, "ids": ids, "point": point}
	if _trace != null:
		_trace.write(frame, "command_request", {"command": command})
	var result: Dictionary = Adapter.queue(operation_owner, command)
	if _trace != null:
		if result.ok:
			_trace.write(frame, "command_queued", {"record": result.record})
		else:
			_trace.write(frame, "command_rejected", {"error": result.error, "path": result.path})
	_status.text = kind if result.ok else "%s / %s" % [result.error, result.path]
	if result.ok and _can_record_replay:
		_replay_commands.append(result.record)

func _reset_replay_recording(candidate: RefCounted, restored: bool) -> void:
	_replay_recording = {}
	_replay_commands = []
	_export_replay.hide()
	_can_record_replay = true
	if not restored:
		return
	var captured: Dictionary = candidate.capture_checkpoint()
	_can_record_replay = captured.ok
	if not captured.ok:
		return
	_replay_commands = Adapter.recording_prefix(captured.packet)

func _select_replay_file() -> void:
	if _file_dialog != null or _returning or _replay_recording.is_empty():
		return
	_file_processing = false
	_file_dialog = FileDialog.new()
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.title = "Export replay"
	_file_dialog.filters = PackedStringArray(["*" + ReplayCodec.EXTENSION + " ; Space Battle replay"])
	_file_dialog.current_file = "battle" + ReplayCodec.EXTENSION
	add_child(_file_dialog)
	_file_dialog.canceled.connect(_close_external_dialog)
	_file_dialog.file_selected.connect(_export_replay_file)
	_file_dialog.popup_centered_ratio(0.7)
	_file_dialog.get_line_edit().grab_focus()

func _export_replay_file(path: String) -> void:
	if _file_dialog == null:
		return
	_close_external_dialog()
	var written := ReplayCodec.write(_replay_recording, path)
	_save_status.text = "Replay exported" if written.ok else error_text(written)

## Invoke only after publishing the explicitly selected versioned owner.
## An operation replacement drops the renderer and must opt in again.
func enable_certified_formation_presentation() -> bool:
	var authority := operation_owner as FormationOwner
	if authority == null or brief == null or brief.operation_request().get("capability") != FormationOwner.CAPABILITY 			or started or _formation_renderer != null or frame.is_empty() or _field == null:
		return false
	var operation_id := authority.presentation_identity()
	if operation_id.is_empty() or frame.get("meta", {}).get("operation_id") != operation_id:
		return false
	var source := FormationSource.new(operation_id, _world)
	source.install_frame(frame)
	var rows := source.squadrons()
	if rows.size() != 1 or rows[0].dead:
		return false
	var id: int = rows[0].id
	var renderer := FleetRenderer.new()
	if not renderer.enable_p05_formation_routes({id: FormationSource.SQUADRON}, operation_id, true):
		renderer.free()
		return false
	var anchor := Node3D.new()
	anchor.position.y = 15.0
	anchor.scale = Vector3.ONE / CameraRig.S
	_field.add_child(anchor)
	anchor.add_child(renderer)
	renderer.setup(source)
	renderer.update(0.0)
	if not renderer.vis.has(id) or renderer.vis[id].p05 == null:
		anchor.free()
		return false
	_formation_source = source
	_formation_renderer = renderer
	if _markers.has(id):
		_markers[id].hide()
	return true


func _install_frame(next: Dictionary) -> void:
	frame = next
	if _formation_source != null:
		_formation_source.install_frame(frame)
	_time.text = "Tick %d   %.1f s" % [frame.tick, frame.clock_ms / 1000.0]
	var states := PackedStringArray()
	for id in ["A", "B", "C"]:
		var site: Dictionary = frame.projection.operation.sites[id]
		states.append("%s: %s%s" % [id, site.control, " (active)" if site.active else ""])
	_sites.text = "   ".join(states)
	var seen := {}
	for row in frame.projection.squadrons:
		if row.get("dead", false) or row.get("out", ""):
			continue
		seen[row.id] = true
		if not _markers.has(row.id):
			_markers[row.id] = _marker(14.0, Color.CORNFLOWER_BLUE if row.side == 0 else Color.ORANGE_RED)
		_markers[row.id].position = _position(row.pos, 15.0)
		_markers[row.id].visible = _formation_source == null or _formation_source.squadron(row.id).is_empty()
	for id in _markers.keys():
		if not seen.has(id):
			_markers[id].queue_free()
			_markers.erase(id)
	if not frame.events.is_empty():
		_status.text = str(frame.events.back().get("kind", ""))

func _reset_field(points: Array) -> void:
	for button in _commands:
		_panel.remove_child(button)
		button.queue_free()
	_commands.clear()
	_markers.clear()
	_formation_source = null
	_formation_renderer = null
	if _field != null:
		remove_child(_field)
		_field.queue_free()
	_field = Node3D.new()
	add_child(_field)
	_build_field(points)

func _build_field(points: Array) -> void:
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = _world.x * 1.3
	camera.position = Vector3(0, 1500, 0)
	camera.rotation_degrees.x = -90
	camera.far = 3000.0
	_field.add_child(camera)
	camera.make_current()
	for i in points.size():
		var beacon := _marker(8.0, Color.GOLD)
		beacon.position = _position(points[i], 0.0)
		if i > 0:
			_command("Move to waypoint %d" % i, "move", points[i])
	_command("Stop", "stop")
	_command("Withdraw", "withdraw")
	_command("Finalize withdrawal", "finalize_withdrawal")

func _position(point: Vector2, height: float) -> Vector3:
	return Vector3(point.x - _world.x * 0.5, height, point.y - _world.y * 0.5)

func _marker(radius: float, color: Color) -> MeshInstance3D:
	var marker := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	marker.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	marker.material_override = material
	_field.add_child(marker)
	return marker

func _build_panel() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_panel = VBoxContainer.new()
	_panel.position = Vector2(24, 24)
	_panel.theme = UiTheme.build()
	layer.add_child(_panel)
	_time = Label.new()
	_panel.add_child(_time)
	_sites = Label.new()
	_panel.add_child(_sites)
	_status = Label.new()
	_status.text = brief.operation_route()
	_panel.add_child(_status)
	_return = _button("Return to map", return_to_map)
	_save = _button("Save battle", _save_battle)
	_save.name = "SaveBattle"
	_save.disabled = true
	_load = _button("Load battle", _load_battle)
	_load.name = "LoadBattle"
	_load.disabled = true
	_export = _button("Export battle\u2026", _select_external_file.bind(true))
	_export.name = "ExportBattle"
	_export.disabled = true
	_import = _button("Import battle\u2026", _select_external_file.bind(false))
	_import.name = "ImportBattle"
	_import.disabled = true
	_save_status = Label.new()
	_panel.add_child(_save_status)
	_cancel_restore = _button("Cancel restore", _cancel_battle_restore)
	_cancel_restore.hide()
	_export_replay = _button("Export replay…", _select_replay_file)
	_export_replay.name = "ExportReplay"
	_export_replay.hide()

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 42
	button.pressed.connect(action)
	_panel.add_child(button)
	return button

func _command(text: String, kind: String, point := Vector2.ZERO) -> void:
	var button := _button(text, _issue.bind(kind, point))
	if kind != "move":
		button.name = "Operation_" + kind
	button.disabled = true
	_commands.append(button)

func _save_battle() -> void:
	if _save.disabled or _returning or _file_dialog != null:
		return
	var captured: Dictionary = operation_owner.capture_checkpoint()
	if not captured.ok:
		_save_status.text = error_text(captured)
		return
	var saved := SaveStore.write(captured.packet, PRODUCT_SLOT_PATH if _is_product() else SaveStore.SLOT_PATH)
	_save_status.text = "Saved at tick %d" % frame.tick if saved.ok else error_text(saved)

func _load_battle() -> void:
	if _load.disabled or _returning or _restore_job != null or _file_dialog != null:
		return
	var saved := read_saved_battle(_is_product())
	if not saved.ok:
		_save_status.text = error_text(saved)
		return
	_restore_battle(saved.payload)

func _select_external_file(exporting: bool) -> void:
	if _file_dialog != null or _restore_job != null or _returning:
		return
	if (_export if exporting else _import).disabled:
		return
	_file_processing = is_processing()
	set_process(false)
	_file_dialog = external_save_dialog(exporting)
	add_child(_file_dialog)
	_file_dialog.canceled.connect(_close_external_dialog)
	_file_dialog.file_selected.connect(_external_file_selected.bind(exporting))
	_file_dialog.popup_centered_ratio(0.7)
	_file_dialog.get_line_edit().grab_focus()

func _close_external_dialog() -> void:
	if _file_dialog == null:
		return
	_file_dialog.hide()
	_file_dialog.queue_free()
	_file_dialog = null
	set_process(_file_processing)

func _external_file_selected(path: String, exporting: bool) -> void:
	if _file_dialog == null:
		return
	_close_external_dialog()
	if not exporting:
		var product := _is_product()
		var imported := read_external_battle(path, product)
		if imported.ok and product:
			var status := Settlements.check_product_unsettled(imported.payload.operation_id)
			if not status.ok:
				imported = status
		if imported.ok:
			_restore_battle(imported.payload, product)
		else:
			_save_status.text = error_text(imported)
		return
	var codec := _external_save_codec()
	if codec == null:
		_save_status.text = "external_save_unavailable / codec"
		return
	var captured: Dictionary = operation_owner.capture_checkpoint()
	if not captured.ok:
		_save_status.text = error_text(captured)
		return
	var saved: Dictionary = codec.write(captured.packet, path, _is_product())
	_save_status.text = "Exported at tick %d" % frame.tick if saved.ok else error_text(saved)

func _restore_battle(packet: Dictionary, external_product := false) -> void:
	var pending := begin_restore(packet, brief)
	if not pending.ok:
		_save_status.text = error_text(pending)
		return
	var job: RefCounted = pending.job
	_restore_job = job
	_restore_processing = is_processing()
	set_process(false)
	for button: Button in _commands + [_start, _save, _load, _export, _import]:
		_restore_buttons[button] = button.disabled
		button.disabled = true
	_save_status.text = restore_progress(0, int(packet.tick))
	_cancel_restore.show()

	while _restore_job == job:
		await get_tree().process_frame
		if _restore_job != job:
			return
		var next: Dictionary = job.step(RESTORE_BUDGET_USEC)
		if not next.ok:
			job.cancel()
			_finish_battle_restore()
			_save_status.text = error_text(next)
			return
		if next.done:
			_finish_battle_restore()
			var result: Dictionary
			if external_product:
				result = Settlements.publish_unsettled_product(packet.operation_id,
					_publish_candidate.bind(next.owner, pending.brief, true))
				if not result.ok:
					next.owner.close()
			else:
				result = _publish_candidate(next.owner, pending.brief, true)
			if not result.ok:
				_save_status.text = error_text(result)
			return
		_save_status.text = restore_progress(next.tick, next.total)

func _finish_battle_restore() -> void:
	_restore_job = null
	for button: Button in _restore_buttons:
		button.disabled = _restore_buttons[button]
	_restore_buttons.clear()
	set_process(_restore_processing)
	_cancel_restore.hide()

func _cancel_battle_restore() -> void:
	if _restore_job == null:
		return
	_restore_job.cancel()
	_finish_battle_restore()
	_save_status.text = "Restore cancelled"

func _fail(problem: Dictionary) -> void:
	failure = {"error": problem.get("error", "operation_failed"), "path": problem.get("path", "runtime")}
	_status.text = error_text(failure)
	if _trace != null:
		_trace.write(frame, "operation_failed", failure)
		_trace.close(frame, "failed")
	_stop()

func _stop() -> void:
	set_process(false)
	_save.disabled = true
	_load.disabled = true
	_export.disabled = true
	_import.disabled = true
	for button in _commands:
		button.disabled = true

func return_to_map() -> void:
	if _returning or _file_dialog != null:
		return
	_cancel_battle_restore()
	_returning = true
	var outcome := settlement
	if outcome != null and _is_product() and product_save_supported() and not _product_settlement_committed:
		var committed := Settlements.consume(outcome, Settlements.PRODUCT_SLOT_PATH)
		if not committed.ok:
			_returning = false
			_save_status.text = error_text(committed)
			_return.text = "Retry map return"
			return
		# This host may still need to publish after a failed scene change.
		_product_settlement_committed = committed.applied
		if not _product_settlement_committed:
			outcome = null
	var reason: int = link.ReturnReason.INITIAL_PREPARE_FAILED if operation_owner == null else link.ReturnReason.NORMAL
	var error: Error = link.back_to_world(outcome, reason)
	if error != OK:
		_returning = false
		_return.text = "Retry map return (%d)" % error

func _exit_tree() -> void:
	if _trace != null:
		_trace.close(frame, "host_exit")
	if _restore_job != null:
		_restore_job.cancel()
		_restore_job = null
	if operation_owner != null:
		operation_owner.close()

