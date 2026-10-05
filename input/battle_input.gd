class_name BattleInput
extends Node

# 마우스·키보드 입력: 선택, 그룹, 끌기, 카메라 이동·확대, 명령 단축키. 명령은 BattleCommands를 거친다.
# 선택·그룹·끌기 같은 UI 세션 상태는 호스트(전투 노드)의 필드에 둔다(상품화 HUD가 같은 필드를 읽는다).
# 터치 입력은 input/touch/touch_controller.gd가 맡고, 이 파일의 click_at·hit_fleet·zoom을 호스트를 거쳐 쓴다.

var host: Node
var cmds: BattleCommands
var _last_click := 0
var _group_press := {}

func setup(h: Node, c: BattleCommands) -> void:
	host = h
	cmds = c

# 프레임마다: 방향키로 카메라 이동
func poll_camera(dt: float) -> void:
	if host.G.state != "play":
		return
	var ps: float = 700.0 * dt / host.cam_z
	if Input.is_key_pressed(KEY_LEFT):
		host.cam_pos.x -= ps
	if Input.is_key_pressed(KEY_RIGHT):
		host.cam_pos.x += ps
	if Input.is_key_pressed(KEY_UP):
		host.cam_pos.y -= ps
	if Input.is_key_pressed(KEY_DOWN):
		host.cam_pos.y += ps
	host._clamp_cam()

# ---- 히트 테스트 ----
func hit_fleet(sp: Vector2):
	var best = null
	var bd := 1e9
	for f in host.fleets:
		if f.dead:
			continue
		var r: Rect2 = host.label_rect(f)
		if sp.x >= r.position.x - 4.0 and sp.x <= r.end.x + 4.0 and sp.y >= r.position.y - 4.0 and sp.y <= r.end.y + 4.0:
			return f
		var s: Vector2 = host.w2s(f.pos)
		var d := s.distance_to(sp)
		if d < maxf(28.0, 52.0 * host.cam_z) and d < bd:
			bd = d
			best = f
	return best

func click_at(sp: Vector2, btn: int, shift: bool) -> void:
	var f = hit_fleet(sp)
	var sel: Array = host.selected
	if btn == MOUSE_BUTTON_LEFT and f and f.side == 0:
		if shift or host.multi:
			SelectionSet.toggle(sel, f)
		else:
			if sel.size() == 1 and sel[0] == f and Time.get_ticks_msec() - _last_click < 400:
				host.cam_pos = f.pos
			host.selected.assign([f])
		host.inspect = null
		_last_click = Time.get_ticks_msec()
		host.refresh_panel()
		return
	if f and f.side == 1:
		if not host.my_sel().is_empty():
			cmds.order_attack(f)
		else:
			host.inspect = f
			host.refresh_panel()
		return
	if f == null and not host.my_sel().is_empty():
		cmds.order_move(host.s2w(sp))
		return
	if f == null:
		host.inspect = null
		host.refresh_panel()

# 드래그 박스(마우스 왼쪽 끌기, 터치는 다중 모드의 빈 곳 끌기). 아군만, 추가 모드면 기존 선택에 더한다.
func box_select(a: Vector2, b: Vector2, additive: bool) -> void:
	var got := SelectionSet.in_rect(host.alive(0), Rect2(a, Vector2.ZERO).expand(b), host.w2s)
	if got.is_empty():
		return
	if additive or host.multi:
		SelectionSet.add_all(host.selected, got)
	else:
		host.selected.assign(got)
	host.inspect = null
	host.refresh_panel()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_key(event)
		return
	if host.G.state != "play":
		return
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				host.drag = {"s": event.position, "c": event.position, "btn": event.button_index, "moved": false, "mode": "", "shift": event.shift_pressed, "last": event.position}
			MOUSE_BUTTON_WHEEL_UP:
				host._zoom(event.position, 1.12)
			MOUSE_BUTTON_WHEEL_DOWN:
				host._zoom(event.position, 1.0 / 1.12)

func _input(event: InputEvent) -> void:
	var drag: Dictionary = host.drag
	if host.G.state != "play" or drag.is_empty():
		return
	if event is InputEventMouseMotion:
		drag.c = event.position
		if not drag.moved and (drag.c as Vector2).distance_to(drag.s) > 6.0:
			drag.moved = true
			drag.mode = "box" if drag.btn == MOUSE_BUTTON_LEFT else "pan"
		if drag.mode == "pan":
			var d: Vector2 = event.position - (drag.last as Vector2)
			host.cam_pos -= d / host.cam_z
			host._clamp_cam()
		drag.last = event.position
	elif event is InputEventMouseButton and not event.pressed and event.button_index == drag.btn:
		if not drag.moved:
			click_at(drag.s, drag.btn, drag.shift)
		elif drag.mode == "box":
			box_select(drag.s, drag.c, drag.shift)
		host.drag = {}

func _key(e: InputEventKey) -> void:
	if e.keycode == KEY_F1:
		host.toggle_hud()
		return
	if e.keycode == KEY_SPACE:
		host._toggle_menu()
		return
	if host.G.state != "play":
		return
	if e.keycode >= KEY_1 and e.keycode <= KEY_9:
		var n: int = e.keycode - KEY_0
		if e.ctrl_pressed or e.meta_pressed:
			assign_group(n)
		else:
			select_group(n)
		return
	if e.keycode == KEY_ESCAPE:
		host.selected.clear()
		host.inspect = null
		host.refresh_panel()
		return
	if e.ctrl_pressed or e.meta_pressed:
		return
	var key := OS.get_keycode_string(e.keycode)
	for c in host.CMDS:
		if c.key == key:
			cmds.do_cmd(c.id)
			return

# ---- 그룹 ----
func group_down(n: int) -> void:
	_group_press[n] = Time.get_ticks_msec()

func group_up(n: int) -> void:
	var held := Time.get_ticks_msec() - int(_group_press.get(n, 0))
	if held >= 600:
		assign_group(n)
	else:
		select_group(n)

func group_fleets(n: int) -> Array:
	SelectionSet.prune(host.groups, host.by_id)
	var out: Array = []
	for id in host.groups.get(n, []):
		out.append(host.by_id(id))
	return out

func same_sel(g: Array) -> bool:
	return SelectionSet.same(g, host.selected)

func select_group(n: int) -> void:
	if host.G.state != "play":
		return
	var g := group_fleets(n)
	if g.is_empty():
		host.toast("비어 있는 편성입니다 · Ctrl+숫자로 저장")
		return
	if same_sel(g):
		var c := Vector2.ZERO
		for f in g:
			c += f.pos
		host.cam_pos = c / g.size()
	host.selected.assign(g)
	host.inspect = null
	host.refresh_panel()

func assign_group(n: int) -> void:
	var s: Array = host.my_sel()
	if s.is_empty():
		host.toast("저장할 함대를 먼저 선택하세요")
		return
	host.groups[n] = SelectionSet.ids(s)
	host.toast("편성 %d에 %d개 전대 저장" % [n, s.size()])
