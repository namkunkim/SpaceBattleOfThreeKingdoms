class_name MouseController
extends Node

# PC 마우스 컨트롤(터치와 분리). 왼쪽 = 선택·범위 선택(BattleInput), 오른쪽 = 명령.
# 오른쪽 클릭 = 이동(적이면 공격), 오른쪽 끌기 = 누른 곳이 목적지, 끄는 방향이 도착 방향(PoC §7.3). 화면 이동은 가운데 버튼 끌기·방향키.

const MOVE := 14.0   # 클릭과 끌기의 경계(터치 TAP_MOVE와 같다)

var battle: Node
var touch: TouchController
var _right := false      # 오른쪽 버튼 누름 중
var _dragging := false   # 오른쪽 끌기로 도착 방향을 정하는 중
var _start := Vector2.ZERO

func setup(b: Node, t: TouchController) -> void:
	battle = b
	touch = t

# 누름은 HUD가 먼저 받도록 _unhandled_input, 끌기·놓기는 _input
func _unhandled_input(e: InputEvent) -> void:
	if battle != null and e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
		battle.trace.write(battle, "right_press", {"screen": e.position, "state": battle.G.state,
			"selected": battle.selected.map(func(f): return f.id), "emulated": e.device == InputEvent.DEVICE_ID_EMULATION})
	if battle == null or battle.G.state != "play" or e.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT and not battle.my_sel().is_empty():
		_right = true
		_dragging = false
		_start = e.position
		get_viewport().set_input_as_handled()

func _input(e: InputEvent) -> void:
	if not _right or e.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if e is InputEventMouseMotion:
		_motion(e.position)
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
		_release(e.position)
		get_viewport().set_input_as_handled()

func _motion(p: Vector2) -> void:
	if not _dragging:
		if p.distance_to(_start) <= MOVE or battle.my_sel().is_empty():
			return
		_dragging = true
	touch.face_preview = {"p0": battle.s2w(_start), "p1": battle.s2w(p)}

func _release(p: Vector2) -> void:
	battle.trace.write(battle, "right_release", {"screen": p, "start": _start, "dragging": _dragging,
		"world": battle.s2w(p), "selected": battle.selected.map(func(f): return f.id)})
	_right = false
	if _dragging:
		_dragging = false
		var q: Vector2 = touch.face_preview.p0
		var d: Vector2 = battle.s2w(p) - q
		touch.face_preview = {}
		if not battle.my_sel().is_empty():
			battle.order_move(q, false, rad_to_deg(d.angle()))   # 누른 곳으로 이동, 끈 방향으로 도착 방향
		return
	if battle.my_sel().is_empty():   # 끌지 않은 오른쪽 클릭: 이동 / 적이면 공격
		return
	var f = battle._hit_fleet(p)
	if f and f.side == 1:
		battle.order_attack(f)
	elif f == null:
		battle.order_move(battle.s2w(p))
