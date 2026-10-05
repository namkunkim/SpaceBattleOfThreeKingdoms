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

var battle: Node
var touches := {}          # index -> {start, pos, t0}
var mode := ""             # "", "pending", "pan", "order", "pinch", "long"
var origin_fleet = null
var order_from := Vector2.ZERO   # 빈 곳에서 시작한 끌기 명령의 시작 화면 좌표(취소 판정)
var press_t := 0.0
var pinch_d := 0.0
var pinch_c := Vector2.ZERO
var order := {}            # 끌기 명령 미리보기: {from: Vector2(px 화면), to, target, cancel}
var _consumed_index := -1

func setup(b: Node) -> void:
	battle = b
	Input.emulate_mouse_from_touch = true

func _process(delta: float) -> void:
	delta = UiDraw.real_dt(delta)
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
	if e.pressed:
		touches[e.index] = {"start": e.position, "pos": e.position}
		if touches.size() == 1:
			mode = "pending"
			press_t = 0.0
			origin_fleet = battle._hit_fleet(e.position)
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
	elif mode == "order":
		_finish_order(e.position)
	mode = "" if touches.is_empty() else mode
	origin_fleet = null

func _drag(e: InputEventScreenDrag) -> void:
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
		elif origin_fleet and origin_fleet.side == 0:
			mode = "order"
			if not battle.selected.has(origin_fleet):
				battle.selected.clear()
				battle.selected.append(origin_fleet)
				battle.inspect = null
				battle.refresh_panel()
		elif not battle.my_sel().is_empty():   # 선택이 있으면 빈 곳(또는 적) 끌기 = 선택 전체 이동
			mode = "order"
			order_from = tc.start
		else:   # 선택이 없으면 끌기 = 범위 선택. 화면 이동은 두 손가락
			mode = "box"
			battle.drag = {"s": tc.start, "c": e.position, "btn": -1, "moved": true, "mode": "box", "shift": false, "last": e.position}
	if mode == "box":
		battle.drag.c = e.position
	elif mode == "order":
		_update_order(e.position)

# 끌기 명령 미리보기. 전대에서 시작했으면 그 전대, 빈 곳에서 시작했으면 선택의 첫 전대에서 그린다.
# 취소: 시작 지점(전대 또는 처음 짚은 곳) 근처로 되돌려 놓기.
func _update_order(p: Vector2) -> void:
	if origin_fleet == null and battle.my_sel().is_empty():   # 끌기 도중 선택 전대가 모두 사라짐
		order = {}
		return
	var tgt = battle._hit_fleet(p)
	var src = origin_fleet if origin_fleet else battle.my_sel()[0]
	var start: Vector2 = battle.w2s(origin_fleet.pos) if origin_fleet else order_from
	order = {"from_fleet": src, "to": p, "target": tgt if (tgt and tgt.side == 1) else null, "cancel": p.distance_to(start) < CANCEL_R}
	order_preview_changed.emit()

func _finish_order(p: Vector2) -> void:
	var o := order
	order = {}
	order_preview_changed.emit()
	if o.is_empty() or o.cancel:
		return
	if o.target:
		battle.order_attack(o.target)
	else:
		battle.order_move(battle.s2w(p))

func _begin_pinch() -> void:
	mode = "pinch"
	order = {}
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
