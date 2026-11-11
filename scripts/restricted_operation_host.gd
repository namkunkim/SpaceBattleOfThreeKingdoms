extends Control

const Adapter := preload("res://core/battle/operation_runtime_adapter.gd")
const Checkpoint := preload("res://scripts/restricted_operation_checkpoint.gd")
const Durable := preload("res://scripts/o07_supply_owner.gd")
const SUPPLY_ARG := Durable.HOST_ARG
const SUPPLY_SLOT := Durable.HOST_SLOT
const SLOT_PATH := "user://restricted-operation-host.pcopstate"
const INPUT_ARG := "--restricted-operation-input"
const MAX_INPUT_BYTES := 1024 * 1024

var _supply_mode := false
var _durable: RefCounted
var _operation: OperationPrivateState
var _checkpoint: RefCounted
var _save_slot: Button
var _restore_slot: Button
var _return_to_map: Button
var _max_ticks := 0
var _summary := {}
var _projection := {}
var _status: Label
var _view: Label
var _actions: Array[Button] = []

func _ready() -> void:
	var panel := VBoxContainer.new()
	panel.position = Vector2(28, 28)
	panel.theme = UiTheme.build()
	add_child(panel)
	panel.add_child(UiTheme.label("Restricted operation host", "Strong", 24))
	_status = Label.new()
	_status.text = "Launch with --restricted-operation-input PATH"
	panel.add_child(_status)
	_view = Label.new()
	panel.add_child(_view)
	for action in [["Issue move", _move.bind(false)], ["Queue move", _move.bind(true)], ["Advance one tick", advance]]:
		var button := Button.new()
		button.text = action[0]
		button.pressed.connect(action[1])
		button.disabled = true
		panel.add_child(button)
		_actions.append(button)
	_save_slot = Button.new()
	_save_slot.name = "SaveSlot"
	_save_slot.text = "Save slot"
	_save_slot.disabled = true
	_save_slot.pressed.connect(_save_slot_pressed)
	panel.add_child(_save_slot)
	_restore_slot = Button.new()
	_restore_slot.name = "RestoreSlot"
	_restore_slot.text = "Restore slot"
	_restore_slot.disabled = true
	_restore_slot.pressed.connect(_restore_slot_pressed)
	panel.add_child(_restore_slot)
	_return_to_map = Button.new()
	_return_to_map.name = "ReturnO07SettlementToMap"
	_return_to_map.text = "Return to map"
	_return_to_map.hide()
	_return_to_map.pressed.connect(_show_settlement_on_map)
	panel.add_child(_return_to_map)
	var args := OS.get_cmdline_user_args()
	_supply_mode = SUPPLY_ARG in args
	if _supply_mode:
		_restore_slot.text = "Resume O07 supply slot"
		_restore_slot.disabled = false
		_status.text = "O07 supply slot · load input or resume"
		var input_index := args.find(INPUT_ARG)
		if input_index >= 0 and input_index + 1 < args.size():
			_report(load_runtime_file(args[input_index + 1]))
	elif args.size() == 2 and args[0] == INPUT_ARG:
		_report(load_runtime_file(args[1]))

func load_runtime_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return Adapter.fail("input_read_failed", "input")
	var length := file.get_length()
	if length > MAX_INPUT_BYTES:
		return Adapter.fail("input_size_limit", "input")
	var bytes := file.get_buffer(length)
	if bytes.size() != length or file.get_length() != length:
		return Adapter.fail("input_read_failed", "input")
	var text := bytes.get_string_from_utf8()
	var parser := JSON.new()
	if text.to_utf8_buffer() != bytes or parser.parse(text) != OK:
		return Adapter.fail("invalid_json", "input")
	return prepare(parser.data)

# This host uses manual commands. CLI automation policies are explicit and
# have no implicit equivalent here.
func prepare(input: Variant) -> Dictionary:
	var created := Adapter.create(input)
	if not created.ok:
		return created
	var candidate: OperationPrivateState = created.owner
	if created.policy != "none":
		candidate.close()
		return Adapter.fail("unsupported_host_policy", "policy")
	var summary := candidate.summary()
	var projection := candidate.read_projection(0)
	if not summary.ok or not projection.ok or summary.summary.tick != 0 or summary.summary.clock_ms != 0 \
			or summary.summary.commands != 0 or projection.projection.tick != 0:
		candidate.close()
		return Adapter.fail("invalid_host_initial_frame", "owner")
	_install_operation(candidate, created.max_ticks)
	return {"ok": true}

func _install_operation(candidate: OperationPrivateState, limit: int, durable: RefCounted = null) -> void:
	var previous := _operation
	_operation = candidate
	_durable = durable
	_max_ticks = limit
	_checkpoint = null if _supply_mode else Checkpoint.bind_owner(candidate, limit)
	_refresh()
	if previous != null and previous != candidate:
		previous.close()

func issue(command: Dictionary) -> Dictionary:
	return _submit(command, false)

func queue(command: Dictionary) -> Dictionary:
	return _submit(command, true)

func _submit(command: Dictionary, pending: bool) -> Dictionary:
	if not _can_step():
		return Adapter.fail("host_not_running", "host")
	var result := _operation.queue(command) if pending else _operation.issue(command)
	if result.ok:
		_refresh()
	return result

func advance() -> Dictionary:
	if not _can_step():
		return Adapter.fail("host_not_running", "host")
	var result: Dictionary = _durable.advance() if _durable != null else _operation.advance()
	if result.ok:
		if _durable != null:
			_operation = _durable._owner
		_refresh()
	_report(result)
	return result

func save_slot() -> Dictionary:
	if _supply_mode:
		if _operation == null:
			return Adapter.fail("host_not_prepared", "host")
		if _durable != null:
			return _durable.save()
		var started := Durable.begin(_operation, SUPPLY_SLOT, _max_ticks)
		if started.ok:
			_durable = started.session
			_update_display()
		return started
	if not _can_step():
		return Adapter.fail("host_not_running", "host")
	return _checkpoint.write_checkpoint(SLOT_PATH)

func restore_slot() -> Dictionary:
	if _supply_mode:
		var opened := Durable.open(SUPPLY_SLOT)
		if opened.ok:
			var resumed: RefCounted = opened.session
			_install_operation(resumed._owner, resumed.max_ticks(), resumed)
		return opened
	if _checkpoint == null:
		return Adapter.fail("host_not_prepared", "host")
	var restored: Dictionary = _checkpoint.restore_checkpoint(SLOT_PATH)
	if restored.ok:
		_refresh()
	return restored

func _save_slot_pressed() -> void:
	var result := save_slot()
	_report(result)
	if result.ok:
		_status.text = "Saved slot at tick %d" % _summary.tick

func _restore_slot_pressed() -> void:
	var result := restore_slot()
	_report(result)
	if result.ok:
		_status.text = "Restored slot at tick %d" % _summary.tick

func _show_settlement_on_map() -> void:
	if not _return_to_map.visible:
		return
	var restored: Dictionary = _durable.read_current_terminal_outcome()
	if not restored.ok:
		_report(restored)
		return
	if restored.outcome == null or restored.outcome.settlement_id != _durable.settlement_key():
		_report(Adapter.fail("settlement_head_unavailable", "host"))
		return
	var error: Error = get_node("/root/WorldLink").show_native_o07_settlement(restored.outcome)
	if error != OK:
		_report(Adapter.fail("map_scene_failed", "host"))

func _move(pending: bool) -> void:
	for fleet in _projection.squadrons:
		if fleet.side == 0 and not fleet.get("dead", false):
			var command := BattleSim.command(0, [fleet.id], "move", -1, fleet.pos + Vector2(100, 0))
			_report(queue(command) if pending else issue(command))
			return

func _refresh() -> void:
	_summary = _operation.summary().summary
	_projection = _operation.read_projection(0).projection
	_update_display()

func _can_step() -> bool:
	return _operation != null and not _summary.over and _summary.tick < _max_ticks \
		and (not _supply_mode or (_durable != null and not _durable._read_only))

func _report(result: Dictionary) -> void:
	_status.text = "" if result.ok else "%s / %s" % [result.error, result.get("path", "owner")]

func _update_display() -> void:
	var lines := PackedStringArray(["Tick %d / %d   Clock %d ms   Applied commands %d"
		% [_summary.tick, _max_ticks, _summary.clock_ms, _summary.commands]])
	for fleet in _projection.squadrons:
		lines.append("%d  %s  %s" % [fleet.id, fleet.get("name", fleet.get("contact", "")), fleet.pos])
	if _supply_mode:
		var native := _operation.observe()
		for fleet in native.fleets:
			lines.append("Fleet %d · stock ammo %d · materials %d · supplied %d" %
				[fleet.id, fleet.sup_ammo, fleet.sup_mat, fleet.supplied])
		if _durable != null:
			lines.append("Last supply key: %s" % _durable.last_key())
			if _summary.over:
				lines.append("Settlement: %s / %d ms" % [_summary.reason, _summary.end_ms])
				lines.append("Settlement key: %s" % _durable.settlement_key())
	_view.text = "\n".join(lines)
	for button in _actions:
		button.disabled = not _can_step()
	_save_slot.disabled = (_durable != null and _durable._read_only) if _supply_mode else not _can_step()
	_restore_slot.disabled = not _supply_mode and _checkpoint == null
	_return_to_map.visible = _durable != null and not _durable._read_only and not _durable.settlement_key().is_empty()

func _exit_tree() -> void:
	_checkpoint = null
	_durable = null
	if _operation != null:
		_operation.close()
		_operation = null

