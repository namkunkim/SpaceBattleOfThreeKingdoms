class_name FormationTab
extends RefCounted

# 진형 탭(docs/ui/FORMATION-TAB-SPEC.md). 코어 진형 7종(Q10) 카드를 만든다.
# 규칙·시간·선택 불가 판정은 코어가 하고(투영 `form_info`), 여기서는 읽어 보여 줄 뿐이다.
# options()는 투영 전대 사전(또는 같은 키를 가진 사전)과 combat 규칙 사전만 받는 순수 함수라 헤드리스로 시험한다.

# 지시명: 본편 정본 data/formations.json `directive` (새로 짓지 않는다)
const DIRECTIVE := {"FRM-01": "중앙 돌파", "FRM-02": "양익 포위", "FRM-03": "종심 방어", "FRM-04": "사격 전개",
	"FRM-05": "축차 투입", "FRM-06": "종렬 항진", "FRM-07": "—"}
# 도형 실루엣: 본편 app/views/formation_spec.gd SHAPE
const SHAPE := {"FRM-01": "wedge", "FRM-02": "arc", "FRM-03": "rings", "FRM-04": "rake", "FRM-05": "barbs", "FRM-06": "bar", "FRM-07": "star"}
const BLOCK_TEXT := {"formation_terrain": "지형이 허용하지 않는 진형", "unknown_formation": "알 수 없는 진형"}

static func _pct(bp: int) -> String:
	return ("%+d%%" % (bp / 100)).replace("-", "−")

static func _name(combat: Dictionary, fid: String) -> String:
	return str(combat.formations[fid].name)

# 선택 전대 sel(투영 사전 배열)에 대한 카드 목록. 진형 정보가 없으면(POC 규칙) 빈 배열.
static func options(combat: Dictionary, sel: Array) -> Array:
	var rows: Array = []
	for s in sel:
		if str(s.get("formation_id", "")) != "":
			rows.append(s)
	if combat.is_empty() or rows.is_empty():
		return []
	var fr: Dictionary = combat.formation_rules
	var ids: Array = combat.formations.keys()
	ids.sort()
	var out: Array = []
	for fid in ids:
		var fm: Dictionary = combat.formations[fid]
		var n_cur := 0
		var n_to := 0
		var n_block := 0
		var secs := 0.0
		var left := 0.0
		var code := ""
		for s in rows:
			var info: Dictionary = s.get("form_info", {}).get(fid, {})
			if str(s.formation_id) == fid:
				n_cur += 1
			if str(s.get("form_to", "")) == fid:
				n_to += 1
				left = maxf(left, float(s.get("form_left_s", 0.0)))
			if str(info.get("block", "")) != "":
				n_block += 1
				code = str(info.block)
			secs = maxf(secs, float(info.get("secs", 0.0)))
		var n := rows.size()
		var state := "ok"
		var line := "%d초" % ceili(secs)
		var warn := secs > float(fr.transition_s) + 0.01
		var reason := ""
		if n_cur == n:
			state = "current"
			line = "현재"
			warn = false
		elif n_to > 0:
			state = "to"
			line = "전환 %d초" % ceili(left)
			warn = false
		elif n_block == n:
			state = "locked"
			line = "잠김"
			warn = false
		elif n_block > 0:
			line = "%d개 제외" % n_block
		if n_block > 0:
			reason = _block_text(fr, code)
		# 현재 진형 칸은 전환 중에 누르면 전환 취소다(코어: 현재 진형 지정 = 취소)
		var any_moving := false
		for s in rows:
			if str(s.get("form_to", "")) != "":
				any_moving = true
		var cancel: bool = state == "current" and any_moving
		var fx := [["화력", _pct(int(fm.fire_bp)), int(fm.fire_bp) >= 0], ["방어", _pct(int(fm.defense_bp)), int(fm.defense_bp) >= 0],
			["탐지", _pct(int(fm.detection_bp)), int(fm.detection_bp) >= 0], ["기동", _pct(int(fm.mobility_bp)), int(fm.mobility_bp) >= 0]]
		var foot := ["요구 통솔 %d" % int(fm.required_command)]
		if n_block == 0 or n_block < n:
			foot.append("전환 %d초" % ceili(secs) + (" (표준 %d초보다 느림: 통솔·지휘 한도)" % int(fr.transition_s) if warn else ""))
		var hint := _affinity_text(combat, fid)
		if hint != "":
			foot.append(hint)
		if reason != "":
			foot.append("⚠ " + reason + ("" if n_block == n else " (%d개 함대 제외)" % n_block))
		out.append({"id": fid, "name": _name(combat, fid), "directive": DIRECTIVE.get(fid, ""), "shape": SHAPE.get(fid, "wedge"),
			"state": state, "line": line, "warn": warn, "cancel": cancel, "reason": reason, "fx": fx, "foot": " · ".join(foot)})
	return out

static func _block_text(fr: Dictionary, code: String) -> String:
	if code == "formation_master":
		return "통솔 %d 이상 + '%s' 특성 필요" % [int(fr.master_min_command), fr.master_trait]
	return str(BLOCK_TEXT.get(code, code))

# 상성 힌트: 이 진형이 강한/약한 상대. 적 진형은 투영이 주지 않으므로 내 칸에 붙인다.
static func _affinity_text(combat: Dictionary, fid: String) -> String:
	var fr: Dictionary = combat.formation_rules
	if fid == fr.master_id:
		return "상성 판정 무효"
	var parts := []
	if fr.affinity.has(fid):
		parts.append("%s에 강함" % _name(combat, str(fr.affinity[fid])))
	for k in fr.affinity:
		if fr.affinity[k] == fid:
			parts.append("%s에 약함" % _name(combat, str(k)))
	var dm := float(combat.damage.formation_damage_mul.get(fid, 1.0))
	if dm < 1.0:
		parts.append("피해 ×%.1f" % dm)
	return (" · ".join(parts) + " (교전 거리대 ×%.1f)" % float(fr.affinity_mul)) if parts.size() > 0 and fr.affinity.has(fid) else " · ".join(parts)

# 툴팁(`CommandDeck.make_cmd_tooltip`)용 명령 사전
static func tooltip_cmd(o: Dictionary) -> Dictionary:
	var d := "지시: %s." % o.directive if o.directive != "—" else "약점 없는 진형."
	if o.cancel:
		d += " 누르면 진행 중인 전환을 취소합니다."
	return {"label": o.name, "key": o.foot.get_slice(" · ", 0), "desc": d, "fx": o.fx, "foot": o.foot.substr(o.foot.find(" · ") + 3) if " · " in o.foot else "", "cost": 0}

# 진형 카드 버튼. 크기는 명령 버튼(78×80)과 같다.
class FormButton extends Button:
	var cmd := {}
	var deck: Node
	var opt := {}
	var cool := 0.0
	var cool_text := ""
	var blocked := false
	var hold_k := 0.0
	func _init(o: Dictionary, d: Node) -> void:
		deck = d
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(78, 80)
		tooltip_text = " "
		set_option(o)
	func set_option(o: Dictionary) -> void:
		opt = o
		cmd = FormationTab.tooltip_cmd(o)
		cmd["id"] = "formation:" + str(o.id)
		queue_redraw()
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var cur: bool = opt.state == "current"
		var lock: bool = opt.state == "locked"
		var hov: bool = is_hovered() or opt.state == "to"
		draw_rect(r, Color(0.07, 0.1, 0.12, 0.88) if (hov or cur) else Color(0.04, 0.06, 0.08, 0.78))
		draw_rect(r.grow(-0.5), UiTheme.GOLD_HI if cur else (UiTheme.GOLD if hov else UiTheme.LINE), false, 2.0 if cur else 1.0)
		var tint: Color = UiTheme.INK_4 if (lock or blocked) else (UiTheme.GOLD_HI if cur else UiTheme.INK)
		_shape(opt.shape, Rect2(size.x * 0.5 - 17, 10, 34, 24), tint)
		UiDraw.text(self, Vector2(0, 52), opt.name, "medium", 13, tint, HORIZONTAL_ALIGNMENT_CENTER, size.x)
		var lc: Color = UiTheme.WARN if opt.warn else (UiTheme.GOLD_HI if (cur or opt.state == "to") else UiTheme.INK_3)
		if lock or blocked:
			lc = UiTheme.INK_4
		UiDraw.text(self, Vector2(0, 70), opt.line, "regular", 11, lc, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	# 본편 FormationSpec 실루엣(색에만 의존하지 않는 도형)
	func _shape(kind: String, r: Rect2, c: Color) -> void:
		var cx := r.get_center()
		match kind:
			"wedge":
				draw_colored_polygon(PackedVector2Array([Vector2(r.position.x, r.end.y), Vector2(cx.x - 2, r.position.y), Vector2(cx.x - 2, r.end.y)]), c)
				draw_colored_polygon(PackedVector2Array([Vector2(r.end.x, r.end.y), Vector2(cx.x + 2, r.position.y), Vector2(cx.x + 2, r.end.y)]), c)
			"arc":
				draw_arc(Vector2(cx.x, r.end.y), r.size.x * 0.5, PI * 1.12, PI * 1.88, 18, c, 2.4, true)
			"rings":
				draw_arc(cx, r.size.y * 0.5, 0.0, TAU, 20, c, 2.0, true)
				draw_arc(cx, r.size.y * 0.25, 0.0, TAU, 14, c, 2.0, true)
			"rake":
				for i in 3:
					draw_line(Vector2(r.position.x + i * 10.0, r.end.y), Vector2(r.position.x + 10.0 + i * 10.0, r.position.y), c, 2.2, true)
			"barbs":
				for i in 3:
					var x := r.position.x + 5.0 + i * 12.0
					draw_colored_polygon(PackedVector2Array([Vector2(x - 5, r.end.y - 3 - i * 4), Vector2(x, r.position.y + 2 + (2 - i) * 4), Vector2(x + 5, r.end.y - 3 - i * 4)]), c)
			"bar":
				draw_rect(Rect2(r.position.x + 2, cx.y - 2, r.size.x - 4, 4), c)
			"star":
				for i in 4:
					var a := PI * 0.25 * i
					draw_line(cx - Vector2(cos(a), sin(a)) * 11.0, cx + Vector2(cos(a), sin(a)) * 11.0, c, 2.0, true)
	func _make_custom_tooltip(_for_text: String) -> Object:
		return deck.make_cmd_tooltip(cmd)
