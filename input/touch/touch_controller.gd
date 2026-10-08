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
const FACE_HOLD_T := 1.0   # 선택된 함대를 이만큼 누르고 있으면 제자리 방향 메뉴
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
	if battle.TOUCH_TEST and not battle.G.hold:
		return null   # 일시정지 중에만 회전 핸들·제자리 방향 메뉴
	var s: Array = battle.my_sel()
	return s[0] if (s.size() == 1 and not battle.multi) else null

# 함대 명령(이동·평행 이동·방향 메뉴·공격)은 일시정지 중에만 낸다(시험 모드). 막히면 안내한다.
var _hint_t := -10.0

func _control_ok() -> bool:
	if not battle.TOUCH_TEST or battle.G.hold:
		return true
	var now := Time.get_ticks_msec() / 1000.0
	if now - _hint_t > 2.0:
		_hint_t = now
		battle.toast("일시정지 후 함대를 조작하세요")
	return false

func handle_pos(f) -> Vector2:
	var c: Vector2 = battle.w2s(f.pos)
	var d: Vector2 = battle.w2s(f.pos + Vector2(cos(f.heading), sin(f.heading)) * 100.0) - c
	return c + (d.normalized() if d.length() > 0.001 else Vector2.RIGHT) * RING_R

# 일시정지/재개 고정 버튼: 이 버튼을 누를 때만 전투 시계가 멈추고(G.hold) 다시 흐른다. 전장 터치는 정지시키지 않는다.
var _resume: Button
var _float: Button
var _float_t := 0.0
const FLOAT_SHOW := 2.5   # 초(실제 시간)
var menu := {}             # 도착 방향 메뉴: {fleet, world(목적지), c(메뉴 중심, 화면), strafe}. 열려 있는 동안 mode == "menu"
var _dwell_t := 0.0
var _dwell_p := Vector2.ZERO

# HUD 버튼·패널의 화면 영역 목록(보이는 STOP 컨트롤 중 화면 40% 미만). 전체 화면을 덮는 컨트롤은 제외한다.
func _hud_rects() -> Array:
	var out := []
	var hud = battle.presentation.hud if battle.presentation else null
	if hud == null:
		return out
	var vs: Vector2 = battle.get_viewport().get_visible_rect().size
	var stack: Array = [hud]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for ch in n.get_children():
			stack.append(ch)
		if n is Control and n != hud and n.is_visible_in_tree() and n.mouse_filter == Control.MOUSE_FILTER_STOP:
			var r: Rect2 = n.get_global_rect()
			if r.size.x * r.size.y < vs.x * vs.y * 0.4:
				out.append(r)
	return out

# HUD 버튼·패널 위 터치인가(정지를 걸지 않는다)
func _over_hud(p: Vector2) -> bool:
	for r in _hud_rects():
		if r.has_point(p):
			return true
	return false

# 원(중심 c, 반지름 rad)이 사각형과 겹치는가
static func _circle_hits(c: Vector2, rad: float, r: Rect2) -> bool:
	var q := Vector2(clampf(c.x, r.position.x, r.end.x), clampf(c.y, r.position.y, r.end.y))
	return q.distance_to(c) < rad

# 원을 HUD를 피해 놓는다: 원하는 중심에서 가장 가까운 빈 자리(격자 탐색). 빈 자리가 없으면 화면 안으로만 당긴다.
func _free_center(want: Vector2, rad: float) -> Vector2:
	var vs: Vector2 = battle.get_viewport().get_visible_rect().size
	var rects := _hud_rects()
	var best := Vector2(clampf(want.x, rad, vs.x - rad), clampf(want.y, rad, vs.y - rad))
	var best_d := INF
	var found := false
	var y := rad
	while y <= vs.y - rad:
		var x := rad
		while x <= vs.x - rad:
			var c := Vector2(x, y)
			var ok := true
			for r in rects:
				if _circle_hits(c, rad, r):
					ok = false
					break
			if ok:
				var d := c.distance_to(want)
				if d < best_d:
					best_d = d
					best = c
					found = true
			x += 20.0
		y += 20.0
	return best

# 재개 버튼 자리: 사용자 지정(명령 패널 왼쪽 빈 곳)
func _place_resume() -> void:
	var vs: Vector2 = battle.get_viewport().get_visible_rect().size
	# 사용자 지정 자리: 명령 패널 왼쪽, 함대 카드 오른쪽의 빈 곳. 화면 비율로 고정한다(HUD 판정으로 옮기지 않는다)
	_resume.size = Vector2(vs.x * 0.12, vs.y * 0.2)
	_resume.position = Vector2(vs.x * 0.64, vs.y * 0.70)

func _build_resume() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 8
	add_child(layer)
	_resume = Button.new()
	_resume.text = "▶ 재개"
	_resume.add_theme_font_size_override("font_size", 38)
	_resume.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_resume.visible = false
	_resume.focus_mode = Control.FOCUS_NONE
	_resume.pressed.connect(func(): battle.G.hold = false)
	layer.add_child(_resume)
	# 플레이 중 화면을 짚으면 짚은 곳에 뜨는 일시정지 버튼(잠시 뒤 사라진다)
	_float = Button.new()
	_float.text = "⏸ 일시정지"
	_float.add_theme_font_size_override("font_size", 30)
	_float.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_float.size = Vector2(230, 84)
	_float.visible = false
	_float.focus_mode = Control.FOCUS_NONE
	_float.pressed.connect(func():
		battle.G.hold = true
		_float.visible = false)
	layer.add_child(_float)

func _show_float(p: Vector2) -> void:
	if _float == null or battle.G.hold or battle.G.state != "play":
		return
	var vs: Vector2 = battle.get_viewport().get_visible_rect().size
	var sz: Vector2 = _float.size
	# 손가락에 가리지 않게 짚은 곳 위쪽에 둔다. 화면 밖으로 나가지 않게 당긴다.
	_float.position = Vector2(clampf(p.x - sz.x * 0.5, 8.0, vs.x - sz.x - 8.0), clampf(p.y - sz.y - 70.0, 8.0, vs.y - sz.y - 8.0))
	_float.visible = true
	_float_t = FLOAT_SHOW

func _process(delta: float) -> void:
	if _float and _float.visible:
		_float_t -= UiDraw.real_dt(delta)
		if _float_t <= 0.0 or battle.G.hold or battle.G.state != "play":
			_float.visible = false
	if _resume:
		# 고정 버튼은 정지 중에만 "▶ 재개"로 보인다. 플레이 중에는 터치 지점의 일시정지 버튼만 쓴다.
		_resume.visible = battle.G.state == "play" and battle.G.hold
		_resume.text = "▶ 재개"
		_place_resume()
	delta = UiDraw.real_dt(delta)
	if mode == "order" and touches.size() == 1 and not order.is_empty() and not order.cancel and order.target == null:
		_dwell_t += delta
		if _dwell_t >= DWELL_T:
			_open_menu()
	if mode == "pending" and touches.size() == 1:
		press_t += delta
		if origin_fleet != null and origin_fleet == handle_fleet():
			# 선택된 함대 1개를 가만히 누르면 제자리 방향 메뉴(선택 추가/해제 길게 누르기보다 우선)
			if press_t >= FACE_HOLD_T:
				_open_menu(true)
		elif press_t >= LONG_PRESS and origin_fleet and origin_fleet.side == 0:
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
			if menu.get("set", false) or e.position.distance_to(menu_ok_pos()) < MENU_OK_R:
				_menu_confirm()   # 방향을 정한 뒤 손을 떼면 자동 확정(확정 버튼 위에서 떼도 확정)
			return
		touches.erase(e.index)
		return
	if e.pressed:
		if touches.is_empty() and not (_float and _float.visible and _float.get_global_rect().has_point(e.position)):
			_show_float(e.position)
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
		if menu.drag == e.index and e.position.distance_to(menu.c) > 18.0 and e.position.distance_to(menu_ok_pos()) >= MENU_OK_R:
			menu.a = (e.position - menu.c).angle()   # 확정 버튼 위로 옮기는 동안은 방향을 바꾸지 않는다
			menu.set = true
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
			mode = "order" if (origin_fleet and origin_fleet.side == 0 and battle.selected.has(origin_fleet) and _control_ok()) else "ignore"
			_dwell_t = 0.0
			_dwell_p = e.position
		elif origin_fleet and origin_fleet.side == 0:   # 선택이 없으면 아군에서 끌기 = 그 전대 선택 + 명령
			if not _control_ok():
				mode = "ignore"
				return
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
	# 이동은 항상 방향 고정 평행 이동(선회 없음). 적 위에 놓으면 공격
	var tgt = null if mode == "slide" else battle._hit_fleet(p)
	var src = origin_fleet
	var start: Vector2 = battle.w2s(origin_fleet.pos)
	order = {"from_fleet": src, "to": p, "target": tgt if (tgt and tgt.side == 1) else null, "cancel": p.distance_to(start) < CANCEL_R, "slide": true}
	order_preview_changed.emit()

func _open_menu(face := false) -> void:
	var o := order
	var f = origin_fleet if face else o.from_fleet
	if face:
		o = {"to": battle.w2s(f.pos)}
	var c: Vector2 = _free_center(o.to, MENU_R + 8.0)
	# 화살표 시작 방향 = 함대의 현재 선두 방향(화면 각도)
	var d: Vector2 = battle.w2s(f.pos + Vector2(cos(f.heading), sin(f.heading)) * 100.0) - battle.w2s(f.pos)
	menu = {"fleet": f, "world": battle.s2w(o.to), "to": o.to, "c": c, "face": face, "a": d.angle(), "drag": touches.keys()[0] if touches.size() == 1 else -1}   # 누르고 있는 손가락이 이어서 방향을 정한다
	mode = "menu"
	order = {}
	order_preview_changed.emit()
	UiSound.vibrate(30)

# 화살표(화면 각도)를 월드 각도(도)로
func menu_deg() -> float:
	var dir := Vector2.from_angle(menu.a)
	return rad_to_deg((battle.s2w(menu.to + dir * 100.0) - battle.s2w(menu.to)).angle())

# 확정 버튼은 원 중심(목적지) 아래쪽에 둔다
func menu_ok_pos() -> Vector2:
	return menu.c + Vector2(0, MENU_R * 0.55)

func _menu_confirm() -> void:
	var f = menu.fleet
	var w: Vector2 = menu.world
	var deg := menu_deg()
	var face: bool = menu.face
	menu = {}
	mode = ""
	origin_fleet = null
	order_preview_changed.emit()
	if f and not f.dead and not battle.my_sel().is_empty():
		if face:
			battle.order_face(deg_to_rad(deg))
		else:
			battle.order_move(w, true, deg)   # 방향 고정 이동 + 이동하면서 정한 방향으로 돌아선다

func _menu_press(e: InputEventScreenTouch) -> void:
	var d: float = e.position.distance_to(menu.c)
	if e.position.distance_to(menu_ok_pos()) < MENU_OK_R:
		_menu_confirm()
	elif d < MENU_R + MENU_BAND:
		menu.drag = e.index
		menu.a = (e.position - menu.c).angle()
		menu.set = true
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
	if _float:
		_float.visible = false
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
