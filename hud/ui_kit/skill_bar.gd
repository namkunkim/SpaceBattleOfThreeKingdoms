extends Control

# 장수 특기 줄(P8c): 선택 정보 패널 아래쪽. 단일 선택 아군 함대에만 뜬다(적·다중 선택은 숨김).
# 왼쪽 슬롯 버튼 3개(이름·유형 색·상태), 오른쪽 받은 효과 칩(다른 함대가 건 버프·디버프, 남은 초).
# 규칙은 계산하지 않는다. 투영 skills {slots, fx}(아군 전용)를 읽고, 누르면 skill 명령만 보낸다. 가부는 코어가 판정해 토스트가 된다.

const H := 64.0   # 정보 패널이 이만큼 늘어난다
const BTN := Vector2(132, 56)
# 유형 색(유형 7종), 고유 기술은 금색
const TYPE_COL := {"firepower": Color("ff7550"), "defense": Color("86aaff"), "maneuver": Color("5fe0cf"), "morale": Color("ffc99a"),
	"disrupt": Color("c58cff"), "detection": Color("7fd6ff"), "supply": Color("86e39a")}

var deck: Node
var fleet = null   # 지금 보여 주는 FleetView
var btns: Array = []

class SlotButton extends Button:
	var slot := {}
	var idx := 0
	func _init(i: int) -> void:
		idx = i
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(132, 56)
		size = custom_minimum_size
	func col() -> Color:
		return UiTheme.GOLD if slot.get("kind", "") == "unique" else TYPE_COL.get(slot.get("type", ""), UiTheme.INK_3)
	# 상태 문구와 색
	func status() -> Array:
		if slot.get("id", "") == "":
			return ["빈 슬롯", UiTheme.INK_4]
		if float(slot.get("active_s", 0.0)) > 0.0:
			return ["발동 중 %d초" % ceili(slot.active_s), UiTheme.LIFE]
		if int(slot.get("uses_left", 0)) <= 0:
			return ["사용함", UiTheme.INK_4]
		if slot.get("block", "") != "":
			return ["조건 미충족", UiTheme.WARN]
		match slot.get("target", ""):
			"enemy_fleet": return ["준비 · 적 함대", UiTheme.CP]
			"ally_fleet": return ["준비 · 아군 함대", UiTheme.CP]
		return ["준비", UiTheme.CP]
	func spent() -> bool:
		return slot.get("id", "") == "" or (int(slot.get("uses_left", 0)) <= 0 and float(slot.get("active_s", 0.0)) <= 0.0)
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var hov := is_hovered() and not disabled
		draw_rect(r, Color(0.07, 0.1, 0.12, 0.88) if hov else Color(0.04, 0.06, 0.08, 0.78))
		var c := col()
		var dim := spent()
		draw_rect(r.grow(-0.5), UiTheme.GOLD if hov else (UiTheme.LINE if dim else Color(c, 0.55)), false, 1.0)
		draw_rect(Rect2(0, 0, 3, size.y), Color(c, 0.35 if dim else 1.0))
		UiDraw.diamond(self, Vector2(15, 18), 5.0, Color(c, 0.4 if dim else 1.0), slot.get("kind", "") != "unique" or not dim)
		if slot.get("kind", "") == "unique":
			UiDraw.diamond(self, Vector2(15, 18), 8.0, Color(c, 0.4 if dim else 0.9), false)
		var nm: String = slot.get("name", "") if slot.get("id", "") != "" else "—"
		UiDraw.text(self, Vector2(28, 24), nm, "semibold", 15, UiTheme.INK_4 if dim else UiTheme.INK)
		var st := status()
		UiDraw.text(self, Vector2(10, 46), st[0], "medium", 11, st[1])

func setup(d: Node) -> void:
	deck = d
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # 칩 자리를 누르면 패널 접기·펼치기가 그대로 된다
	for i in 3:
		var b := SlotButton.new(i)
		b.position = Vector2(14 + i * (BTN.x + 6), 0)
		b.pressed.connect(func(): deck.battle.cmds.do_skill(b.idx))
		add_child(b)
		btns.append(b)
	visible = false

# 보여 줄 함대: 단일 선택 아군 함대이고 투영에 특기가 있을 때만. 다중 선택·적·특기 없는 규칙은 null
static func pick(sel: Array):
	if sel.size() != 1:
		return null
	var f = sel[0]
	if f.side != 0 or f.contact != "" or f.skills.get("slots", []).is_empty():
		return null
	return f

func refresh(f) -> void:
	fleet = f
	visible = f != null
	if f == null:
		return
	var slots: Array = f.skills.slots
	for i in btns.size():
		var b: SlotButton = btns[i]
		b.slot = slots[i] if i < slots.size() else {}
		b.disabled = b.slot.get("id", "") == ""
		var tip: String = b.slot.get("text", "")
		var why: String = b.slot.get("block", "")
		if why != "" and not b.disabled:
			tip += "\n" + deck.battle.reject_text(why)
		if f.control == "delegate":
			tip += "\n위임 중인 함대입니다. 발동하면 직접 지휘로 바뀝니다."
		b.tooltip_text = tip if tip != "" else " "
		b.queue_redraw()
	queue_redraw()

# 받은 효과: 다른 함대가 건 것만(자기가 건 것은 버튼이 "발동 중"으로 보인다). 적이 건 것은 이름만(Q97)
func received() -> Array:
	if fleet == null:
		return []
	return fleet.skills.get("fx", []).filter(func(x): return x.get("foe", false) or int(x.get("src", -1)) != fleet.id)

func _draw() -> void:
	if fleet == null:
		return
	var x0 := 14 + 3 * (BTN.x + 6) + 4
	if fleet.control == "delegate":
		UiDraw.text(self, Vector2(x0, 12), "위임 중 · 발동 시 직접 지휘", "regular", 10, UiTheme.INK_3)
	var fx := received()
	var y := 18.0
	for i in mini(fx.size(), 2):
		var x: Dictionary = fx[i]
		var foe: bool = x.get("foe", false)
		var t := "%s %d초" % [x.name, ceili(float(x.left_s))]
		if i == 1 and fx.size() > 2:
			t += " 외 %d" % (fx.size() - 2)
		var col: Color = UiTheme.FOE_HI if foe else UiTheme.ALLY_HI
		var w := minf(UiDraw.text_w(t, "medium", 11) + 16.0, size.x - x0 - 4)
		var r := Rect2(x0, y, w, 20)
		draw_rect(r, Color(0.03, 0.05, 0.07, 0.7))
		draw_rect(r, Color(col, 0.45), false, 1.0)
		UiDraw.text(self, r.position + Vector2(8, 14), t, "medium", 11, col)
		y += 24.0
