class_name TouchController
extends Node

# 터치 조작(제안서 v0.2 §7.2). 마우스 조작은 POC 입력 처리를 그대로 쓴다.
#  - 탭: 선택(아군) / 선택이 있으면 적 탭 = 공격, 없으면 정보 / 선택이 있을 때 빈 곳 탭 = 선택 해제
#  - 선택이 있을 때 끌기(아군 전대 또는 빈 곳에서 시작): 선택 전체 이동. 적 위에 놓으면 공격, 시작 지점으로 되돌리면 취소
#  - 선택이 없을 때 빈 곳 끌기: 범위 선택 상자(화면 이동은 두 손가락)
#  - 다중 모드 `battle.multi`: 끌기 = 범위 선택(기존 선택에 더함), 아군 탭 = 추가/해제, 빈 곳 탭은 선택 유지
#  - 길게 누르기(아군): 선택에 추가/제외
#  - 두 손가락: 확대·축소와 화면 이동
#
# Godot는 터치를 마우스(장치 ID = DEVICE_ID_EMULATION)로도 흉내 낸다. HUD 버튼은 그 흉내 이벤트로 눌린다.
# 전장으로 내려온(HUD가 받지 않은) 흉내 마우스 이벤트는 여기서 막아 POC의 마우스 끌기 상자 선택과 겹치지 않게 한다.

signal order_preview_changed

const TAP_MOVE := 14.0
const LONG_PRESS := 0.5
const CANCEL_R := 46.0
const RING_R := 84.0       # 회전 핸들 링 반지름(화면 단위)
const HANDLE_HIT := 40.0   # 핸들 잡기 반경
const RING_BAND := 26.0    # 링 잡기 폭(±)
const DWELL_T := 1.0       # 끌다가 이만큼 멈추면 그 자리가 목적지, 방향 메뉴가 뜬다
const DWELL_MOVE := 14.0
const MENU_R := 130.0      # 방향 원 반지름
const MENU_OK_R := 46.0    # 가운데 확정 버튼 반경
const MENU_BAND := 56.0    # 원 바깥으로 이만큼까지는 방향 조작, 그 밖을 누르면 취소

var battle: Node
var touches := {}          # index -> {start, pos, t0}
var mode := ""             # "", "pending", "ignore", "box", "order", "pinch", "long"
var origin_fleet = null
var press_t := 0.0
var pinch_d := 0.0
var pinch_c := Vector2.ZERO
var turn := {}             # 회전 미리보기: {fleet, rad(월드 각도), cancel}
var order := {}            # 끌기 명령 미리보기: {from: Vector2(px 화면), to, target, cancel}
var _consumed_index := -1

func setup(b: Node) -> void:
	battle = b
	if b.TOUCH_TEST:
		_build_resume()
	Input.emulate_mouse_from_touch = true

# 회전 핸들: 단일 선택 함대의 선두 방향, 링 위. 선택이 1개가 아니면 없다.
func handle_fleet():
	var s: Array = battle.my_sel()
	return s[0] if (s.size() == 1 and not battle.multi) else null

func handle_pos(f) -> Vector2:
	var c: Vector2 = battle.w2s(f.pos)
	var d: Vector2 = battle.w2s(f.pos + Vector2(cos(f.heading), sin(f.heading)) * 100.0) - c
	return c + (d.normalized() if d.length() > 0.001 else Vector2.RIGHT) * RING_R

# 터치 정지: 전장을 짚으면 전투 시계를 멈추고(G.hold), 이 버튼으로 재개한다.
var _resume: Button
var menu := {}             # 도착 방향 메뉴: {fleet, world(목적지), c(메뉴 중심, 화면), strafe}. 열려 있는 동안 mode == "menu"
var _dwell_t := 0.0
var _dwell_p := Vector2.ZERO
var _hold_by_touch := false   # 이번 터치가 정지를 걸었는가(두 손가락 카메라 조작이면 되돌린다)

func _build_resume() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 8
	add_child(layer)
	_resume = Button.new()
	_resume.text = "▶ 재개"
	_resume.add_theme_font_size_override("font_size", 38)
	_resume.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_resume.offset_left = -330
	_resume.offset_right = -40
	_resume.offset_top = -190
	_resume.offset_bottom = -70
	_resume.visible = false
	_resume.pressed.connect(func(): battle.G.hold = false)
	layer.add_child(_resume)

func _process(delta: float) -> void:
	if _resume:
		_resume.visible = battle.G.state == "play" and battle.G.hold
	delta = UiDraw.real_dt(delta)
	if mode == "order" and touches.size() == 1 and not order.is_empty() and not order.cancel and order.target == null:
		_dwell_t += delta
		if _dwell_t >= DWELL_T:
			_open_menu()
	if mode == "pending" and touches.size() == 1:
		press_t += delta
		if press_t >= LONG_PRESS and origin_fleet and origin_fleet.side == 0:
			mode = "long"
			SelectionSet.toggle(battle.selected, origin_fleet)
			battle.inspect = null
			battle.refresh_panel()
			UiSound.vibrate(30)

func _unhandled_input(e: InputEvent) -> void:
	# 전장에 내려온 터치 흉내 마우스는 POC로 보내지 않는다.
	if (e is InputEventMouseButton or e is InputEventMouseMotion) and e.device == InputEvent.DEVICE_ID_EMULATION:
		get_viewport().set_input_as_handled()
		return
	if battle == null or battle.G.state != "play":
		return
	if e is InputEventScreenTouch:
		_touch(e)
		get_viewport().set_input_as_handled()
	elif e is InputEventScreenDrag:
		_drag(e)
		get_viewport().set_input_as_handled()

func _touch(e: InputEventScreenTouch) -> void:
	if not menu.is_empty():
		if e.pressed:
			_menu_press(e)
		elif menu.get("drag", -1) == e.index:
			menu.drag = -1
		touches.erase(e.index)
		return
	if e.pressed:
		if _resume and not (_resume.visible and _resume.get_global_rect().has_point(e.position)):
			if touches.is_empty():
				_hold_by_touch = not battle.G.hold
			battle.G.hold = true
		touches[e.index] = {"start": e.position, "pos": e.position}
		if touches.size() == 1:
			mode = "pending"
			press_t = 0.0
			origin_fleet = battle._hit_fleet(e.position)
			var hf = handle_fleet()
			if hf and e.position.distance_to(handle_pos(hf)) < HANDLE_HIT:
				mode = "turn"
				origin_fleet = hf
				_update_turn(e.position)
			elif hf and absf(e.position.distance_to(battle.w2s(hf.pos)) - RING_R) < RING_BAND:
				mode = "slide"   # 링 위에서 끌기 = 방향 고정 평행 이동
				origin_fleet = hf
		elif touches.size() == 2:
			_begin_pinch()
		return
	if not touches.has(e.index):
		return
	var tc: Dictionary = touches[e.index]
	touches.erase(e.index)
	if mode == "pinch":
		if touches.is_empty():
			mode = ""
		return
	if mode == "pending":
		battle._click_at(e.position, MOUSE_BUTTON_LEFT, false)
	elif mode == "box":
		battle.input_node.box_select(battle.drag.s, e.position, false)
		battle.drag = {}
	elif mode == "order" or mode == "slide":
		_finish_order(e.position)
	elif mode == "turn":
		_finish_turn(e.position)
	mode = "" if touches.is_empty() else mode
	origin_fleet = null

func _drag(e: InputEventScreenDrag) -> void:
	if not menu.is_empty():
		if menu.drag == e.index and e.position.distance_to(menu.c) > 18.0:
			menu.a = (e.position - menu.c).angle()
		return
	if not touches.has(e.index):
		return
	var tc: Dictionary = touches[e.index]
	var last: Vector2 = tc.pos
	tc.pos = e.position
	if mode == "pinch" and touches.size() >= 2:
		_update_pinch()
		return
	if mode == "pending" and (e.position - (tc.start as Vector2)).length() > TAP_MOVE:
		if battle.multi:   # 다중 모드: 어디서 시작하든 끌기 = 범위 선택(명령은 탭으로)
			mode = "box"
			battle.drag = {"s": tc.start, "c": e.position, "btn": -1, "moved": true, "mode": "box", "shift": true, "last": e.position}
		elif not battle.my_sel().is_empty():
			# 선택이 있으면 선택된 전대에서 시작한 끌기만 이동·공격으로 인정, 그 밖에서 시작하면 무시
			mode = "order" if (origin_fleet and origin_fleet.side == 0 and battle.selected.has(origin_fleet)) else "ignore"
			_dwell_t = 0.0
			_dwell_p = e.position
		elif origin_fleet and origin_fleet.side == 0:   # 선택이 없으면 아군에서 끌기 = 그 전대 선택 + 명령
			mode = "order"
			_dwell_t = 0.0
			_dwell_p = e.position
			battle.selected.append(origin_fleet)
			battle.inspect = null
			battle.refresh_panel()
		else:   # 선택이 없으면 끌기 = 범위 선택. 화면 이동은 두 손가락
			mode = "box"
			battle.drag = {"s": tc.start, "c": e.position, "btn": -1, "moved": true, "mode": "box", "shift": false, "last": e.position}
	if mode == "box":
		battle.drag.c = e.position
	elif mode == "turn":
		_update_turn(e.position)
	elif mode == "order" or mode == "slide":
		_update_order(e.position)

# 끌기 명령 미리보기. 전대에서 시작했으면 그 전대, 빈 곳에서 시작했으면 선택의 첫 전대에서 그린다.
# 취소: 시작 지점(전대 또는 처음 짚은 곳) 근처로 되돌려 놓기.
func _update_order(p: Vector2) -> void:
	if origin_fleet == null or battle.my_sel().is_empty():   # 끌기 도중 선택 전대가 모두 사라짐
		order = {}
		return
	if p.distance_to(_dwell_p) > DWELL_MOVE:
		_dwell_p = p
		_dwell_t = 0.0
	var slide := mode == "slide"
	var tgt = null if slide else battle._hit_fleet(p)
	var src = origin_fleet
	var start: Vector2 = battle.w2s(origin_fleet.pos)
	order = {"from_fleet": src, "to": p, "target": tgt if (tgt and tgt.side == 1) else null, "cancel": p.distance_to(start) < CANCEL_R, "slide": slide}
	order_preview_changed.emit()

func _open_menu() -> void:
	var o := order
	var f = o.from_fleet
	var bounds: Vector2 = battle.get_viewport().get_visible_rect().size
	var m := MENU_R + MENU_BAND
	var c: Vector2 = Vector2(clampf(o.to.x, m, bounds.x - m), clampf(o.to.y, m + 60.0, bounds.y - m))
	# 화살표 시작 방향 = 함대의 현재 선두 방향(화면 각도)
	var d: Vector2 = battle.w2s(f.pos + Vector2(cos(f.heading), sin(f.heading)) * 100.0) - battle.w2s(f.pos)
	menu = {"fleet": f, "world": battle.s2w(o.to), "to": o.to, "c": c, "a": d.angle(), "drag": touches.keys()[0] if touches.size() == 1 else -1}   # 누르고 있는 손가락이 이어서 방향을 정한다
	mode = "menu"
	order = {}
	order_preview_changed.emit()
	UiSound.vibrate(30)

# 화살표(화면 각도)를 월드 각도(도)로
func menu_deg() -> float:
	var dir := Vector2.from_angle(menu.a)
	return rad_to_deg((battle.s2w(menu.to + dir * 100.0) - battle.s2w(menu.to)).angle())

func _menu_press(e: InputEventScreenTouch) -> void:
	var d: float = e.position.distance_to(menu.c)
	if d < MENU_OK_R:
		var f = menu.fleet
		var w: Vector2 = menu.world
		var deg := menu_deg()
		menu = {}
		mode = ""
		origin_fleet = null
		order_preview_changed.emit()
		if f and not f.dead and not battle.my_sel().is_empty():
			battle.order_move(w, false, deg)
	elif d < MENU_R + MENU_BAND:
		menu.drag = e.index
		menu.a = (e.position - menu.c).angle()
	else:   # 바깥 탭: 취소
		menu = {}
		mode = ""
		origin_fleet = null
		order_preview_changed.emit()

func _update_turn(p: Vector2) -> void:
	var f = origin_fleet
	if f == null or f.dead or battle.my_sel().is_empty():
		turn = {}
		return
	var v: Vector2 = battle.s2w(p) - f.pos
	turn = {"fleet": f, "rad": v.angle(), "cancel": p.distance_to(battle.w2s(f.pos)) < CANCEL_R * 0.6}
	order_preview_changed.emit()

func _finish_turn(_p: Vector2) -> void:
	var t := turn
	turn = {}
	order_preview_changed.emit()
	if not t.is_empty() and not t.cancel:
		battle.order_face(t.rad)

func _finish_order(p: Vector2) -> void:
	var o := order
	order = {}
	order_preview_changed.emit()
	if o.is_empty() or o.cancel:
		return
	if o.target:
		battle.order_attack(o.target)
	else:
		battle.order_move(battle.s2w(p), o.slide)

func _begin_pinch() -> void:
	menu = {}
	if _hold_by_touch:
		battle.G.hold = false
		_hold_by_touch = false
	mode = "pinch"
	order = {}
	turn = {}
	battle.drag = {}
	origin_fleet = null
	var pts := _two()
	pinch_d = maxf(1.0, pts[0].distance_to(pts[1]))
	pinch_c = (pts[0] + pts[1]) * 0.5

func _update_pinch() -> void:
	var pts := _two()
	var d := maxf(1.0, pts[0].distance_to(pts[1]))
	var c: Vector2 = (pts[0] + pts[1]) * 0.5
	battle._zoom(c, d / pinch_d)
	battle.cam_pos -= (c - pinch_c) / battle.cam_z
	battle._clamp_cam()
	pinch_d = d
	pinch_c = c

func _two() -> Array:
	var out := []
	for k in touches:
		out.append(touches[k].pos)
		if out.size() == 2:
			break
	return out
