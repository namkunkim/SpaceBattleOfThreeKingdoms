extends Control
## Standalone tactical campaign scene. Reads only the public battle projection.
const Session = preload("res://core/campaign/open_jump_session.gd")
const RestoreWorker := preload("res://scripts/campaign/open_jump_restore_worker.gd")
const RestoreOverlay := preload("res://scripts/campaign/open_jump_restore_overlay.gd")
const PHASE_NAMES := {"rendezvous": "01 · 황개와 합류", "escort": "02 · 황개 호위", "capture": "03 · 기지 점령", "clash": "04 · 본대 교전", "extraction": "05 · 최종 철수"}
var session: RefCounted
var selected := "liu"
var target_id := -1
var paused := true
var accumulator := 0.0
var map: Control
var phase_label: Label
var details: Label
var notice: Label
var pause_button: Button
var skill_buttons: Array[Button] = []
var _view := {}
var _scale := 1.0
var _offset := Vector2.ZERO
var _restore_job: RefCounted
var _restore_overlay: ColorRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Malgun Gothic", "Arial"])
	add_theme_font_override("font", font)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)
	var stack := VBoxContainer.new()
	margin.add_child(stack)
	var title := Label.new()
	title.text = "적벽 · 열린 도약로"
	title.add_theme_font_size_override("font_size", 25)
	stack.add_child(title)
	phase_label = Label.new()
	stack.add_child(phase_label)
	notice = Label.new()
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.text = "황개는 필수 철수 대상입니다. 황개와 생존 유비·관우 함대 하나 이상이 함께 철수해야 합니다. 황개가 앞서 나가지 않도록 대기로 호위를 모으세요. 출격을 눌러 시작하세요."
	stack.add_child(notice)
	var bar := HFlowContainer.new()
	stack.add_child(bar)
	_button(bar, "유비 선택", func(): selected = "liu"; refresh())
	_button(bar, "관우 선택", func(): selected = "guan"; refresh())
	_button(bar, "선택 함대 정지", func(): issue({"kind": "stop", "fleet": selected}))
	_button(bar, "황개 대기", func(): issue({"kind": "huang_wait"}))
	_button(bar, "황개 전진", func(): issue({"kind": "huang_advance"}))
	_button(bar, "도약 확정", func(): issue({"kind": "confirm_jump"}))
	pause_button = _button(bar, "출격", toggle_pause)
	_button(bar, "저장", save_game)
	_button(bar, "불러오기", load_game)
	_button(bar, "표적 공격", func(): weapon("attack"))
	_button(bar, "미사일", func(): weapon("missile"))
	_button(bar, "함재기", func(): weapon("fighter"))
	_button(bar, "일제사격", func(): weapon("volley"))
	var skill_bar := HFlowContainer.new()
	stack.add_child(skill_bar)
	for index in 3:
		skill_buttons.append(_button(skill_bar, "특기 %d" % (index + 1), func(): issue({"kind": "skill", "fleet": selected, "slot": index})))
	var formations := OptionButton.new()
	for name in ["어린진", "학익진", "방원진", "안행진", "봉시진", "장사진", "팔진"]:
		formations.add_item(name)
	formations.item_selected.connect(func(index): issue({"kind": "formation", "fleet": selected, "formation": "FRM-%02d" % (index + 1)}))
	skill_bar.add_child(formations)
	map = Control.new()
	map.custom_minimum_size = Vector2(640, 350)
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.mouse_filter = Control.MOUSE_FILTER_STOP
	map.draw.connect(draw_map)
	map.gui_input.connect(map_input)
	stack.add_child(map)
	details = Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(details)
	var help := Label.new()
	help.text = "왼쪽 클릭: 아군 선택·적 표적 지정 / 오른쪽 클릭: 빈 곳 이동·적 공격 / 적 정보는 탐지된 접촉만 표시"
	stack.add_child(help)
	_restore_overlay = RestoreOverlay.new()
	_restore_overlay.add_theme_font_override("font", font)
	add_child(_restore_overlay)
	_restore_overlay.cancelled.connect(_cancel_restore)
	var built := Session.fresh()
	if not built.ok:
		notice.text = "시나리오를 열 수 없습니다: " + str(built.get("error"))
		return
	session = built.session
	session.runtime.drain_events()
	refresh()

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 36
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func toggle_pause() -> void:
	if _restore_job != null:
		return
	paused = not paused
	pause_button.text = "계속" if paused else "일시정지"

func _process(delta: float) -> void:
	if _restore_job != null:
		_update_restore()
		return
	if session == null or paused or session.runtime.sim.st.over:
		return
	accumulator += minf(delta, 0.25)
	while accumulator >= session.runtime.sim.dt:
		accumulator -= session.runtime.sim.dt
		var advanced: Dictionary = session.runtime.advance()
		if not advanced.ok:
			paused = true
			break
		for event in session.runtime.drain_events():
			if event.has("text"):
				notice.text = event.text
			elif event.kind == "rejected":
				notice.text = "명령 실행 불가: " + str(event.get("value", "알 수 없는 사유"))
			elif event.kind == "base_captured":
				notice.text = "인증키 전송 완료. 도약로가 열렸습니다. 주유·정보가 조조 본대를 붙드는 동안 황개와 철수하세요."
		if session.runtime.sim.st.over:
			paused = true
			show_outcome()
			break
	refresh()

func issue(command: Dictionary) -> void:
	if session == null or _restore_job != null:
		return
	var result: Dictionary = session.runtime.queue(command)
	if not result.ok:
		notice.text = "명령을 적용할 수 없습니다: " + str(result.error)
	refresh()

func weapon(kind: String) -> void:
	if target_id < 0:
		notice.text = "지도에서 탐지된 적을 눌러 표적을 지정하세요."
		return
	issue({"kind": kind, "fleet": selected, "target_id": target_id})

func save_game() -> void:
	if session == null or _restore_job != null:
		return
	var result: Dictionary = session.save_to()
	notice.text = "현재 전장과 작전 진행을 저장했습니다." if result.ok else "저장 실패: " + str(result.error)

func load_game() -> void:
	if _restore_job != null:
		return
	_restore_job = RestoreWorker.new(Session.SLOT)
	_restore_overlay.begin()

func _cancel_restore() -> void:
	if _restore_job != null:
		_restore_job.request_cancel()

func _update_restore() -> void:
	var restored: Dictionary = _restore_job.poll()
	if restored.ok and not restored.done:
		if restored.cancelling:
			_restore_overlay.show_cancelling()
		else:
			_restore_overlay.update_progress(restored.tick, restored.total)
		return
	_restore_job = null
	_restore_overlay.hide()
	if not restored.ok:
		notice.text = "불러오기를 취소했습니다." if restored.error == "checkpoint_cancelled" else "불러오기 실패 — 현재 전장은 유지됩니다: " + str(restored.error)
		return
	session = restored.session
	paused = true
	accumulator = 0.0
	pause_button.text = "계속"
	pause_button.disabled = false
	target_id = -1
	notice.text = "저장한 전장에서 재개합니다. 계속을 눌러 진행하세요."
	refresh()

func refresh() -> void:
	if session == null:
		return
	_view = session.runtime.view()
	var state: Dictionary = _view.operation
	phase_label.text = "%s  |  %.1f초  |  점령 %d/%d  |  도약로 %s" % [PHASE_NAMES[state.phase], _view.battle.clock_s, _view.capture_progress, _view.capture_ticks, "개방" if state.jump_open else "봉쇄"]
	var own = session.runtime.fleet(selected)
	var target_name := "미선택"
	for contact in _view.battle.squadrons:
		if int(contact.get("id", -1)) == target_id and int(contact.get("side", 0)) == 1:
			target_name = str(contact.get("name", "접촉"))
	details.text = "%s · 잔존 %.1f척 / %.0f척 · 사기 %.0f · 미사일/함재기 잔여 %s" % [own.role, own.ships / 1000.0, own.max_ships / 1000.0, own.morale_bp / 100.0, "%d / %d" % [int(own.wch.get("artillery", 0)), int(own.wch.get("fighter", 0))]]
	details.text += " · 표적: " + target_name
	for index in 3:
		var skill := str(own.skill_slots[index]) if index < own.skill_slots.size() else ""
		var definition: Dictionary = session.runtime.sim.skills.defs.get(skill, {}) if session.runtime.sim.skills else {}
		skill_buttons[index].text = str(definition.get("name", "빈 특기"))
		skill_buttons[index].tooltip_text = str(definition.get("text", ""))
		var blocked: String = session.runtime.sim.skills.block(own, skill) if skill != "" else "skill_no_slot"
		skill_buttons[index].disabled = own.dead or blocked != ""
		if blocked != "":
			skill_buttons[index].tooltip_text += "\n현재 사용할 수 없습니다: " + blocked
	if session.runtime.sim.st.over:
		show_outcome()
	map.queue_redraw()

func show_outcome() -> void:
	var state: Dictionary = session.runtime.policy.snapshot()
	paused = true
	pause_button.disabled = true
	pause_button.text = "작전 종료"
	if state.outcome == "success":
		notice.text = "철수 성공 — " + ("유비와 관우가 함께 귀환했습니다." if state.evacuated.size() == 2 else "한 함대가 황개와 귀환했습니다. 남은 전력의 손실을 기억합니다.")
	else:
		notice.text = "작전 실패 — 황개 또는 유비·관우 두 부대를 잃었습니다."
	var losses: Dictionary = session.runtime.sim.st.result.get("losses", {})
	var rows := PackedStringArray()
	var names := {"liu": "유비", "guan": "관우", "huang": "황개"}
	for alias in ["liu", "guan", "huang"]:
		if losses.has(alias):
			rows.append("%s %.1f/%.0f척" % [names[alias], float(losses[alias].remaining) / 1000, float(losses[alias].initial) / 1000])
	notice.text += "  " + " · ".join(rows)
func _map_transform() -> void:
	var world: Vector2 = session.runtime.sim.rs.world
	_scale = minf(map.size.x / world.x, map.size.y / world.y)
	_offset = (map.size - world * _scale) * 0.5

func draw_map() -> void:
	map.draw_rect(Rect2(Vector2.ZERO, map.size), Color("101d2d"))
	if session == null:
		return
	_map_transform()
	var font := get_theme_font("font")
	var names := {"rendezvous": "황개 합류", "base": "위군 보급기지", "jump": "도약로", "exit": "철수 구역"}
	for key in _view.regions:
		if key in ["jump", "exit"] and not session.runtime.recon_reported:
			continue
		var zone: Dictionary = _view.regions[key]
		var point := Vector2(zone.center[0], zone.center[1]) * _scale + _offset
		var color := Color("d3bb79") if key in ["jump", "exit"] else Color("7e98ac")
		map.draw_arc(point, float(zone.radius) * _scale, 0, TAU, 60, color, 1.5)
		map.draw_string(font, point + Vector2(4, -10), names.get(key, key), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	if session.runtime.recon_reported:
		var approach: Array = session.runtime.definition.operation.recon.cao_approach
		var from := Vector2(approach[0], approach[1]) * _scale + _offset
		var base: Array = _view.regions.base.center
		var to := Vector2(base[0], base[1]) * _scale + _offset
		var color := Color("e89785")
		map.draw_line(from, to, color, 2)
		var direction := (to - from).normalized()
		map.draw_line(to, to - direction.rotated(0.5) * 15, color, 2)
		map.draw_line(to, to - direction.rotated(-0.5) * 15, color, 2)
		map.draw_string(font, from + Vector2(-100, -12), "정찰 · 조조 접근 방향", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	for fleet in _view.battle.squadrons:
		if fleet.get("dead", false):
			continue
		var position: Vector2 = fleet.get("pos", Vector2.ZERO)
		var point: Vector2 = position * _scale + _offset
		var color := Color("ff8d83") if fleet.get("side", 1) == 1 else Color("8dd5ef")
		map.draw_circle(point, 5.0, color)
		if int(fleet.get("id", -1)) == session.runtime.fleet(selected).id:
			map.draw_arc(point, 10, 0, TAU, 24, Color.WHITE, 2)
		map.draw_string(font, point + Vector2(8, 5), str(fleet.get("name", "접촉")), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)

func map_input(event: InputEvent) -> void:
	if session == null or not event is InputEventMouseButton or not event.pressed:
		return
	_map_transform()
	var point: Vector2 = (event.position - _offset) / _scale
	for contact in _view.battle.squadrons:
		if int(contact.get("side", 0)) == 1 and not contact.get("dead", false):
			var position: Vector2 = contact.get("pos", Vector2.ZERO)
			if position.distance_to(point) * _scale < 24:
				target_id = int(contact.id)
				if event.button_index == MOUSE_BUTTON_RIGHT:
					weapon("attack")
				refresh()
				return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		issue({"kind": "move", "fleet": selected, "point": [point.x, point.y]})
	elif event.button_index == MOUSE_BUTTON_LEFT:
		for alias in ["liu", "guan"]:
			if session.runtime.fleet(alias).pos.distance_to(point) * _scale < 24:
				selected = alias
				refresh()

func _exit_tree() -> void:
	if _restore_job != null:
		_restore_job.cancel_and_join()
		_restore_job = null
	if session != null:
		session.runtime.close()
		session = null



