class_name MouseController
extends Node

# PC 마우스 컨트롤(터치와 분리). 왼쪽 = 선택·범위 선택(BattleInput), 오른쪽 = 명령.
# 오른쪽 클릭 = 이동(적이면 공격), 오른쪽 끌기 = 명령 미리보기 후 놓은 곳으로 이동·공격. 화면 이동은 가운데 버튼 끌기·방향키.
# 터치의 끌기 미리보기(TouchController.order)를 가상 포인터 MI로 재사용한다.

const MI := -2
const MOVE := 14.0   # 클릭과 끌기의 경계(터치 TAP_MOVE와 같다)

var battle: Node
var touch: TouchController
var _right := false      # 오른쪽 버튼 누름 중
var _dragging := false   # 터치 미리보기에 위임 중
var _start := Vector2.ZERO

func setup(b: Node, t: TouchController) -> void:
	battle = b
	touch = t

# 누름은 HUD가 먼저 받도록 _unhandled_input, 끌기·놓기는 _input
func _unhandled_input(e: InputEvent) -> void:
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
		# 오른쪽 끌기 시작: 선택의 첫 전대에서 그리는 명령 미리보기
		_dragging = true
		touch.touches[MI] = {"start": _start, "pos": _start}
		touch.mode = "order"
		touch.origin_fleet = battle.my_sel()[0]
	var d := InputEventScreenDrag.new()
	d.index = MI
	d.position = p
	touch._drag(d)

func _release(p: Vector2) -> void:
	_right = false
	if _dragging:
		_dragging = false
		var t := InputEventScreenTouch.new()
		t.index = MI
		t.position = p
		touch._touch(t)
		return
	if battle.my_sel().is_empty():   # 끌지 않은 오른쪽 클릭: 이동 / 적이면 공격
		return
	var f = battle._hit_fleet(p)
	if f and f.side == 1:
		battle.order_attack(f)
	elif f == null:
		battle.order_move(battle.s2w(p))
