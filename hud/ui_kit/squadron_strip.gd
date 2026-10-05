extends Control

# 전대 띠(EXPERIENCE-DESIGN §6 U4, U9 한 손 조작): 아군 전대 카드를 가로로 늘어놓는다(소유 글리프·이름·막대).
# 카드 위 숫자 배지 = 저장 편성 번호(1~9). 배지를 탭하면 그 편성을 선택한다.
# - 탭: 그 전대만 선택. 이미 선택된 전대를 다시 탭하면 화면을 그 전대로 옮긴다.
# - 길게 누르기: 선택에 추가·제외
# - 띠에서 전장으로 끌기: 빈 곳이면 이동, 적 위면 공격(전장 끌기와 같은 미리보기). 띠 위로 되돌리면 취소.
# 마우스와 터치(마우스 흉내)를 같은 경로로 받는다.

const CELL := Vector2(52, 64)
const GAP := 4.0
const COUNT := 7
const WIDTH := COUNT * (52.0 + 4.0) - 4.0
const DRAG := 14.0
const LONG := 0.5

var deck: Control
var battle: Node
var src: BattleSource
var _press_i := -1
var _press_pos := Vector2.ZERO
var _press_t := 0.0
var _dragging := false
var _long_done := false

func setup(d: Control) -> void:
	deck = d
	battle = d.battle
	src = d.src
	mouse_filter = Control.MOUSE_FILTER_STOP

func fleets() -> Array:
	var out := []
	for f in battle.fleets:
		if f.side == 0:
			out.append(f)
	return out

func cell_rect(i: int) -> Rect2:
	return Rect2(Vector2(i * (CELL.x + GAP), 0), CELL)

func _cell_at(p: Vector2) -> int:
	var fs := fleets()
	for i in fs.size():
		if cell_rect(i).has_point(p):
			return i
	return -1

func _process(delta: float) -> void:
	delta = UiDraw.real_dt(delta)
	if _press_i >= 0 and not _dragging and not _long_done:
		_press_t += delta
		if _press_t >= LONG:
			_long_done = true
			var f = fleets()[_press_i]
			if not f.dead:
				SelectionSet.toggle(battle.selected, f)
				battle.inspect = null
				battle.refresh_panel()
				UiSound.vibrate(30)
	queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if src.state() != "play":
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_press_i = _cell_at(e.position)
			_press_pos = e.position
			_press_t = 0.0
			_dragging = false
			_long_done = false
		else:
			_release(e.position)
		accept_event()
	elif e is InputEventMouseMotion and _press_i >= 0:
		if not _dragging and (e.position - _press_pos).length() > DRAG and not _long_done:
			_begin_drag()
		if _dragging:
			_drag_to(get_global_transform() * e.position)
		accept_event()

func _begin_drag() -> void:
	var f = fleets()[_press_i]
	if f.dead:
		_press_i = -1
		return
	_dragging = true
	if not battle.selected.has(f):
		battle.selected.clear()
		battle.selected.append(f)
		battle.inspect = null
		battle.refresh_panel()

# 끌기 미리보기는 터치 조작기의 명령 미리보기를 그대로 쓴다(전술 오버레이가 그린다).
func _drag_to(gp: Vector2) -> void:
	var t: TouchController = deck.overlay.touch
	var f = fleets()[_press_i]
	t.origin_fleet = f
	t.mode = "order"
	t._update_order(gp)
	# 띠 위로 되돌리면 취소
	if get_global_rect().has_point(gp):
		t.order.cancel = true

func _release(p: Vector2) -> void:
	var i := _press_i
	_press_i = -1
	if i < 0:
		return
	var f = fleets()[i]
	if _dragging:
		_dragging = false
		var t: TouchController = deck.overlay.touch
		t._finish_order(get_global_transform() * p)
		t.mode = ""
		t.origin_fleet = null
		return
	if _long_done or f.dead or _cell_at(p) != i:
		return
	# 배지 영역 탭: 그 편성 전체를 선택한다
	var local := p - cell_rect(i).position
	if local.y < 18.0:
		var bs := _badges(f.id, battle.groups)
		var k := int(local.x / 14.0)
		if k >= 0 and k < bs.size() and k < 2:
			battle.select_group(bs[k])
			return
	# 다중 모드: 탭 = 추가/해제
	if battle.multi:
		SelectionSet.toggle(battle.selected, f)
		battle.inspect = null
		battle.refresh_panel()
		return
	# 탭: 이미 그 전대 하나만 선택돼 있으면 화면을 옮긴다
	if battle.selected.size() == 1 and battle.selected[0] == f:
		battle.cam_pos = f.pos
		battle._clamp_cam()
		return
	battle.selected.clear()
	battle.selected.append(f)
	battle.inspect = null
	battle.refresh_panel()

func _draw() -> void:
	var fs := fleets()
	var groups: Dictionary = battle.groups
	for i in fs.size():
		var f = fs[i]
		var r := cell_rect(i)
		var sel: bool = battle.selected.has(f)
		var fk: String = src.faction(f.id)
		var fc: Color = Factions.of(fk).color
		draw_rect(r, Color(0.03, 0.045, 0.06, 0.78))
		if f.dead:
			UiDraw.faction_glyph(self, r.position + Vector2(r.size.x * 0.5, 22), 8.0, fk, Color(UiTheme.INK_4, 0.7), false)
			draw_line(r.position + Vector2(16, 12), r.position + Vector2(36, 32), UiTheme.FOE, 2.0)
			draw_line(r.position + Vector2(36, 12), r.position + Vector2(16, 32), UiTheme.FOE, 2.0)
			draw_rect(r.grow(-0.5), UiTheme.LINE, false, 1.0)
			continue
		if i == _press_i and not _dragging:
			draw_rect(r, Color(1, 1, 1, 0.08))
		# 소유 글리프(촉 사각·위 마름모·오 원)와 이름, 연속 막대. 초상은 선택 패널에만 둔다.
		UiDraw.faction_glyph(self, r.position + Vector2(r.size.x * 0.5, 22), 8.0, fk, fc)
		UiDraw.text(self, Vector2(r.position.x, r.end.y - 14), f.fname, "medium", 11, UiTheme.GOLD_HI if sel else UiTheme.INK_2, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		var frac: float = f.ships / f.max_ships
		draw_rect(Rect2(r.position.x + 4, r.end.y - 9, r.size.x - 8, 4), UiTheme.SLOT)
		draw_rect(Rect2(r.position.x + 4, r.end.y - 9, (r.size.x - 8) * frac, 4), UiTheme.LIFE if frac > 0.35 else UiTheme.WARN)
		# 상태: 교전 중(빨강 점), 이동 중(화살), 기함(旗)
		if f.fire_t and not f.fire_t.dead:
			draw_circle(r.position + Vector2(r.size.x - 8, 8), 3.5, UiTheme.FOE)
		elif f.has_move or f.target:
			UiDraw.icon(self, "charge", Rect2(r.position + Vector2(r.size.x - 15, 3), Vector2(11, 11)), UiTheme.GOLD_HI, 1.2)
		if f.is_flag:
			UiDraw.text(self, r.position + Vector2(r.size.x - 15, 36), "旗", "serif_bold", 11, UiTheme.GOLD_HI, HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
		# 지휘 상태(리뷰 V-8): ● 직접 / ○ 위임. 세력은 글리프가 맡는다.
		var cm := src.command_mode(f.id)
		if cm != "":
			var dp := r.position + Vector2(9, 38)
			draw_circle(dp, 4.0, Color(0.02, 0.03, 0.05, 0.9))
			if cm == "direct":
				draw_circle(dp, 2.8, UiTheme.ALLY)
			else:
				draw_arc(dp, 2.8, 0.0, TAU, 12, UiTheme.ALLY, 1.2, true)
		# 저장 편성 번호 배지(아라비아 숫자)
		var bx := 3.0
		for n in _badges(f.id, groups):
			var br := Rect2(r.position + Vector2(bx, 3), Vector2(13, 14))
			draw_rect(br, Color(UiTheme.GOLD, 0.9))
			UiDraw.text(self, br.position + Vector2(0, 11), str(n), "bold", 11, Color(0.04, 0.05, 0.06), HORIZONTAL_ALIGNMENT_CENTER, br.size.x)
			bx += 14.0
			if bx > 28.0:
				break
		draw_rect(r.grow(-0.5), UiTheme.GOLD_HI if sel else UiTheme.LINE, false, 1.5 if sel else 1.0)
		if sel:
			draw_rect(Rect2(r.position.x, r.end.y - 2, r.size.x, 2), UiTheme.ALLY)
		# 길게 누르기 진행
		if i == _press_i and not _dragging and not _long_done and _press_t > 0.12:
			draw_arc(r.get_center() + Vector2(0, -8), 16.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(_press_t / LONG, 0.0, 1.0), 24, UiTheme.GOLD_HI, 2.0, true)

# 이 전대가 들어 있는 저장 편성 번호(1~9)
func _badges(id: int, groups: Dictionary) -> Array:
	var out := []
	for n in range(1, 10):
		if groups.has(n) and (groups[n] as Array).has(id):
			out.append(n)
	return out
