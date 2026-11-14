extends "res://scripts/first_operation_host.gd"

const Storage := preload("res://scripts/first_operation_v2_storage.gd")
const Codec := preload("res://scripts/first_operation_v2_record_codec.gd")

signal returned

var _resume_slot: bool


func configure(resume_slot: bool) -> void:
	_resume_slot = resume_slot


func _ready() -> void:
	set_process(false)
	brief = BattleBrief.new()
	brief.select_first_operation_v2()
	_build_panel()
	_status.text = "적벽 v2"
	_return.text = "적벽 v2 메뉴"
	_start = _button("출격", _begin)
	_start.name = "StartOperation"
	_panel.move_child(_start, 3)
	_start.hide()
	_save.text = "작전 저장"
	_load.text = "저장 불러오기"
	_cancel_restore.text = "복원 취소"
	_export_replay.text = "적벽 v2 리플레이 내보내기"
	_export.hide()
	_import.hide()
	if _resume_slot:
		_load_battle_slot()
	else:
		var prepared := FormationOwner.prepare_fresh()
		if not prepared.ok:
			_fail(prepared)
			return
		_publish_v2(prepared.owner, false)


func _publish_v2(candidate: RefCounted, restored: bool) -> void:
	var result := _publish_candidate(candidate, brief, restored)
	if not result.ok:
		if operation_owner == null:
			_fail(result)
		else:
			_save_status.text = error_text(result)
		return
	_start.text = "작전 재개" if restored else "출격"
	_load.disabled = not Storage.has_save()
	enable_certified_formation_presentation()
	_start.grab_focus()


func _begin() -> void:
	super._begin()
	_export.disabled = true
	_import.disabled = true
	_load.disabled = not Storage.has_save()


func _build_field(points: Array) -> void:
	super._build_field(points)
	_command("기함 전대 횡진 전환", "formation")


func _issue(kind: String, point := Vector2.ZERO) -> void:
	if kind != "formation":
		super._issue(kind, point)
		return
	if not started or _returning or _restore_job != null or _file_dialog != null or settlement != null or not failure.is_empty():
		return
	var rows := _formation_source.squadrons() if _formation_source != null else []
	if rows.is_empty() or not _formation_renderer.vis.has(rows[0].id) or _formation_renderer.vis[rows[0].id].p05 == null:
		_status.text = "현재 전대 상태에서는 횡진 전환을 표시할 수 없습니다."
		return
	var result: Dictionary = operation_owner.queue(FormationOwner.FORMATION)
	_status.text = "횡진 전환 명령" if result.ok else error_text(result)


func _reset_replay_recording(_candidate: RefCounted, _restored: bool) -> void:
	_can_record_replay = false
	_replay_recording = {}
	_export_replay.hide()


func step_operation() -> bool:
	var advancing := super.step_operation()
	if settlement != null and _replay_recording.is_empty():
		var captured: Dictionary = operation_owner.capture_record()
		if captured.ok:
			_replay_recording = captured.record
			_export_replay.show()
	return advancing


func _save_battle() -> void:
	if _save.disabled or _returning or _file_dialog != null or operation_owner == null:
		return
	var captured: Dictionary = operation_owner.capture_record()
	var result := Storage.save_slot(captured.record) if captured.ok else captured
	_save_status.text = "%d 틱 저장 완료" % frame.tick if result.ok else error_text(result)
	if result.ok:
		_load.disabled = false


func _load_battle() -> void:
	if not _load.disabled and not _returning and _restore_job == null and _file_dialog == null:
		_load_battle_slot()


func _load_battle_slot() -> void:
	var candidate := Storage.begin_slot_restore()
	if not candidate.ok:
		_save_status.text = error_text(candidate)
		return
	var job: RefCounted = candidate.job
	_restore_job = job
	_restore_processing = is_processing()
	set_process(false)
	for button: Button in _commands + [_start, _save, _load]:
		_restore_buttons[button] = button.disabled
		button.disabled = true
	_save_status.text = "적벽 v2 저장 복원 중"
	_cancel_restore.show()
	while _restore_job == job:
		await get_tree().process_frame
		if _restore_job != job:
			return
		var next: Dictionary = job.step(RESTORE_BUDGET_USEC)
		if not next.ok:
			_finish_battle_restore()
			_save_status.text = error_text(next)
			return
		if next.done:
			_finish_battle_restore()
			_publish_v2(next.owner, true)
			return
		_save_status.text = "%d / %d 틱 복원 중" % [next.tick, next.total]


func _select_replay_file() -> void:
	if _file_dialog != null or _returning or _replay_recording.is_empty():
		return
	_file_processing = false
	_file_dialog = FileDialog.new()
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.title = "적벽 v2 리플레이 내보내기"
	_file_dialog.filters = PackedStringArray(["*" + Codec.REPLAY_EXTENSION + " ; 적벽 v2 리플레이"])
	_file_dialog.current_file = "red-cliffs-v2" + Codec.REPLAY_EXTENSION
	add_child(_file_dialog)
	_file_dialog.canceled.connect(_close_external_dialog)
	_file_dialog.file_selected.connect(_export_replay_file)
	_file_dialog.popup_centered_ratio(0.7)


func _export_replay_file(path: String) -> void:
	if _file_dialog == null:
		return
	_close_external_dialog()
	var result := Storage.export_replay(_replay_recording, path)
	_save_status.text = "리플레이 내보내기 완료" if result.ok else error_text(result)


func return_to_map() -> void:
	if _returning or _file_dialog != null:
		return
	_cancel_battle_restore()
	_returning = true
	_stop()
	returned.emit()
