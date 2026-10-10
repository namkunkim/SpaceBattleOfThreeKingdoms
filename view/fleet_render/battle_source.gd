class_name BattleSource
extends RefCounted

# 표현 계층이 전투 상태를 읽는 유일한 통로.
# 지금은 POC(FleetBattle3D.gd)의 Fleet 객체를 읽는다. M1에서 BattleProjection이 정해지면
# 이 파일만 고쳐 같은 모양의 사전을 돌려주면 된다.
#
# squadron 사전: {id, side, faction, name, role, portrait, pos(px), heading, ships, max_ships, flagship,
#                 dead, target_id, firing_at, formation, defense, charge_t, in_cmd,
#                 missile_cd, fighter_cd, speech, speech_t, has_move, move_to, lv}

var battle: Node

func _init(b: Node) -> void:
	battle = b

func squadrons() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for f in battle.fleets:
		out.append(_sq(f))
	return out

func squadron(id: int) -> Dictionary:
	var f = battle.by_id(id)
	return _sq(f) if f else {}

func _sq(f) -> Dictionary:
	return {
		"id": f.id, "side": f.side, "faction": faction(f.id), "name": f.fname, "role": f.role, "portrait": f.portrait,
		"pos": f.pos, "heading": f.heading, "ships": f.ships, "max_ships": f.max_ships, "counts": f.counts,
		"flagship": f.is_flag, "dead": f.dead,
		"target_id": f.target.id if f.target else -1,
		"firing_at": f.fire_t.id if (f.fire_t and not f.fire_t.dead) else -1,
		"formation": f.shape,
		"formation_name": form_name(f),
		"defense": f.defense, "charge_t": f.charge_t, "in_cmd": f.in_cmd,
		"missile_cd": f.missile_cd, "fighter_cd": f.fighter_cd,
		"speech": f.speech, "speech_t": f.speech_t,
		"has_move": f.has_move, "move_to": f.move_to, "lv": f.lv, "range": f.range_r, "ranges": f.ranges,
			"contact": f.contact,
	}

# 진형 이름: 코어 규칙(7종)의 formation_id. 규칙이 없으면(POC) 빈 문자열.
func form_name(f) -> String:
	if f.contact != "":
		return ""   # 적 진형은 비공개
	return combat.formations.get(f.formation_id, {}).get("name", "")

static func contact_strength_text(f) -> String:
	return "전력 %d/%d" % [f.band, f.max_band] if f.max_band > 0 else "전력 ?"

func missiles() -> Array:
	var out := []
	for m in battle.missiles:
		out.append({"key": m, "pos": m.pos, "side": m.side})
	return out

func swarms() -> Array:
	var out := []
	for s in battle.swarms:
		var pts := []
		for p in s.pts:
			pts.append(p.pos)
		out.append({"side": s.side, "pts": pts, "life": s.life})
	return out

func state() -> String:
	return battle.G.get("state", "")

func clock_s() -> float:
	return battle.G.get("t", 0.0)

func slow() -> float:
	return float(battle.G.get("slow", 1.0))

func speed() -> int:
	return int(battle.G.get("speed", 1))

func camera() -> Camera3D:
	return battle.camera

func zoom() -> float:
	return battle.cam_z

func to3(p: Vector2, y := 0.0) -> Vector3:
	return battle.w3(p, y)

func world_size() -> Vector2:
	return battle.WORLD

func unit_scale() -> float:
	return battle.S

# ------------------------------------------------------------ 시간 진행(Q52)
# 교전 거리대: 주포·미사일·함재기 중 가장 긴 사거리에 여유를 더한 거리.
const ENGAGE_MARGIN := 1.15

# 조용한 구간인가: 어느 아군·적 전대도 교전 거리대에 없고, 날아가는 미사일·함재기도 없다.
# 안개(M6, 리뷰 V-2): 보는 적은 투영의 접촉(확인·추정)뿐이다. 상실 접촉은 뺀다. `battle.fleets`는 투영 뷰 모델이라
# 미탐지 적의 위치로 자동 ×4가 풀리지 않는다. 미탐지 적이 쏘면 `drain_events_for`가 주는 사격 사건(`sq` = -1)으로 끝난다.
func quiet() -> bool:
	if not battle.missiles.is_empty() or not battle.swarms.is_empty():
		return false
	var reach := maxf(battle.MISSILE_R, battle.FIGHTER_R) * ENGAGE_MARGIN
	for a in battle.fleets:
		if a.dead or a.side != 0:
			continue
		for b in battle.fleets:
			if b.dead or b.side == 0 or b.contact == "lost":
				continue
			if a.pos.distance_to(b.pos) <= maxf(reach, maxf(a.range_r, b.range_r) * ENGAGE_MARGIN):
				return false
	return true

# 접적까지 예상 시간(게임 초, 리뷰 U8 "접적까지 약 40초"). 가장 가까운 아군·적 쌍이 서로 다가간다고 본 어림값.
# POC 이동 속도는 62 × 함대 속도 계수다. 조용하지 않으면 0.
func engage_eta() -> float:
	var reach := maxf(battle.MISSILE_R, battle.FIGHTER_R) * ENGAGE_MARGIN
	var best := INF
	for a in battle.fleets:
		if a.dead or a.side != 0:
			continue
		for b in battle.fleets:
			if b.dead or b.side == 0 or b.contact == "lost":
				continue
			var gap: float = a.pos.distance_to(b.pos) - maxf(reach, maxf(a.range_r, b.range_r) * ENGAGE_MARGIN)
			best = minf(best, maxf(0.0, gap) / maxf(1.0, 62.0 * (a.spd + b.spd)))
	return 0.0 if best == INF else best

# 플레이어가 선택한 아군 전대의 명령 서명. 바뀌면 명령이 확정된 것이다(Q31 "명령이 확정되면 원래 속도").
func order_signature() -> String:
	var parts := PackedStringArray()
	for f in battle.my_sel():
		parts.append("%d:%s:%d,%d:%d:%s:%s" % [f.id, f.has_move, roundi(f.move_to.x), roundi(f.move_to.y), f.target.id if f.target else -1, f.defense, f.charge_t > 0.0])
	return ";".join(parts)

func has_selection() -> bool:
	return not battle.my_sel().is_empty()

# 선택 감속 배율(×0.2). 코어 TickClock의 누산기 소비 속도만 바꾼다(`FleetBattle3D._process`가 G.speed와 곱한다). Engine.time_scale은 건드리지 않는다.
func set_time_scale(k: float) -> void:
	battle.G.slow = k

# 배속 설정. 표현 계층이 전투 시계를 바꾸는 유일한 통로다(POC는 프레임당 시뮬레이션 횟수).
func set_speed(n: int) -> void:
	battle.G.speed = n

# ------------------------------------------------------------ 규칙 값(화면 문구용)
# 화면의 효과 문구(측면·후면, 명령 설명)는 이 값으로 만든다(hud/ui_kit/rule_text.gd).
# set = "poc": 지금 돌아가는 POC 규칙. FleetBattle3D.gd의 리터럴과 같아야 한다(tests/rule_text.gd가 대조한다).
# 코어가 확정 규칙(v0.2: Q33 방향 = 명중률 보정, Q42 돌격 = 열 40%·사기 안정, 방어진형 삭제)으로 바뀌면
# 여기서 set = "v02"와 그 값을 돌려주고, 문구는 rule_text.gd의 v02 틀로 자동으로 바뀐다.
func rules() -> Dictionary:
	if battle.sim.salvo:
		return _salvo_rules()
	return {
		"set": "poc",
		"flank": {"model": "damage", "side": 1.3, "rear": 1.6},
		"out_of_cmd_fire": 0.75,
		"defense": {"taken": 0.6, "fire": 0.7, "speed": 0.5},
		"charge": {"fire": 1.35, "speed": 1.4, "dur": 10.0, "cost": 3, "ends_defense": true},
		"missile": {"range": battle.MISSILE_R, "cd": 18.0, "cost": 2, "n": 6},
		"fighter": {"range": battle.FIGHTER_R, "cd": 26.0, "dur": 9.0, "cost": 3},
		"cmd_range": battle.CMD_R,
	}

# set = "v02": salvo 규칙(적벽 프로필)의 문구용 값. 방향은 정면 대비 명중 가산(방어 보정 차), 사기 타격은 구역 가중.
func _salvo_rules() -> Dictionary:
	var c: Dictionary = combat
	var d: Dictionary = c.sector.defense_bp
	var w: Dictionary = c.morale.hit.sector_weight_bp
	var bp := float(BattleRules.BP)
	return {
		"set": "v02",
		"flank": {"model": "hit",
			"side": {"hit": (d.front - d.flank) / 100.0, "morale": w.flank / bp},
			"rear": {"hit": (d.front - d.rear) / 100.0, "morale": w.rear / bp}},
		"out_of_cmd_hit": c.hit.out_of_command_bp / 100.0,
		"charge": {"heat": c.charge.heat_share_bp / bp, "min_morale": c.charge.min_morale_bp / bp},
		"cmd_range": battle.CMD_R,
	}

# 지금 규칙에 있는 명령(진형·태세 탭 구성). salvo 규칙에는 방어진형이 없다(미사일·함재기는 일제사격 당기기).
func has_command(id: String) -> bool:
	if battle.sim.salvo:
		return id != "def"
	return true

# ------------------------------------------------------------ 진형 탭(M5 진형, docs/ui/FORMATION-TAB-SPEC.md)
# combat: 코어 규칙 사전(`combat.formations`·`formation_rules`). salvo 규칙(시나리오 프로필)이 아니면 비어 진형 탭이 안 선다.
var combat: Dictionary:
	get: return battle.sim.salvo.C if battle.sim.salvo else {}

func formation_options() -> Array:
	var sel := []
	for f in battle.my_sel():
		if f.side == 0:
			sel.append({"formation_id": f.formation_id, "form_to": f.form_to, "form_left_s": f.form_left_s, "form_info": f.form_info})
	return FormationTab.options(combat, sel)

# 지휘력(CP)은 POC 규칙의 자원이다. salvo 규칙(시나리오 프로필)은 CP를 쓰지 않는다.
func uses_cp() -> bool:
	return battle.sim.salvo == null

func has_formations() -> bool:
	return not combat.is_empty()

# 공격 방향: "front" | "side" | "rear" (표적 기준)
func attack_dir(att_id: int, tgt_id: int) -> String:
	var a = battle.by_id(att_id)
	var t = battle.by_id(tgt_id)
	if a == null or t == null:
		return "front"
	var m: float = battle.flank_mul(a, t)
	return "rear" if m > 1.45 else ("side" if m > 1.05 else "front")

# ------------------------------------------------------------ 세력(C-3)
# 세력 키: "shu"(촉) | "wei"(위) | "wu"(오). 투영의 faction(시나리오 세력 ID 기준)을 읽는다.
# faction_override는 미리보기·캡처용이다.
var faction_override := {}

func faction(id: int) -> String:
	if faction_override.has(id):
		return faction_override[id]
	var f = battle.by_id(id)
	if f == null:
		return "shu"
	return f.faction if f.faction != "" else ("wei" if f.side == 1 else "shu")

# 지휘 상태(Q20, 리뷰 V-1): "direct"(직접 지휘 ●) | "delegated"(위임 ○) | ""(모름).
# 세력과 무관하다(유비 전대도 위임할 수 있고 손권 전대에도 직접 명령할 수 있다). 세력은 글리프가 맡는다.
# POC에는 위임 개념이 없어 ""를 돌려준다(표시하지 않는다). 코어의 지휘 상태가 생기면 이 함수만 고친다.
func command_mode(_id: int) -> String:
	return ""

# ------------------------------------------------------------ 함종 카운터(리뷰 C-1)
# 전대의 함종별 실제 척 수 [[함종 이름, 수], ...](코어 카운터, 격침·대파 제외 = 전력에 드는 척). 카운터가 없으면(적 접촉·POC) 빈 배열.
func composition(id: int) -> Array:
	var f = battle.by_id(id)
	var out := []
	if f == null:
		return out
	for t in f.counts:
		var st: Array = f.counts[t]
		var n: int = st[0] + st[1] + st[2]
		if n > 0:
			out.append([ScenarioRoster.SHIP_TYPES.get(t, {"short": t}).short, n])
	return out

# ------------------------------------------------------------ 결정 분기(EXPERIENCE-DESIGN §5)
# 곧 분기(리뷰 V-4): 약 3초 전 예고. {"secs": 남은 게임 초, "pos": 관련 위치(전장 px)}. 없으면 {}.
# POC에는 분기가 없다. incoming_override는 미리보기·테스트용이다.
var incoming_override := {}

func decision_incoming() -> Dictionary:
	return incoming_override

# 군 사기(제안서 §4.12, Q21): {"value": 현재, "max": 최대, "ticks": [임계 값, ...]}. 없으면 {}.
# POC에는 사기가 없다. 값이 없으면 상단 바는 전력(척 수 비율)만 그린다. 가짜 값으로 채우지 않는다.
func morale(_side: int) -> Dictionary:
	return {}

# 국면 이름(접적·교전 등). POC에는 없어 ""(화면에서 숨긴다).
func phase() -> String:
	return ""

# 코어에 결정 분기가 생기면 {"done": 2, "total": 5}를 돌려준다. POC에는 없으므로 비운다(화면에서 숨긴다).
func decision_progress() -> Dictionary:
	return {}

# ------------------------------------------------------------ 명령 되돌리기(EXPERIENCE-DESIGN §6 U2)
# 아군 전대의 명령 상태 스냅숏 {id: [has_move, move_to, target_id, defense]}.
func order_snapshot() -> Dictionary:
	var out := {}
	for f in battle.fleets:
		if f.side == 0 and not f.dead:
			out[f.id] = [f.has_move, f.move_to, f.target.id if f.target else -1, f.defense]
	return out

# 스냅숏의 명령 상태로 되돌린다. 코어에서는 "직전 상태로 돌아가는 새 명령"(restore)으로 발행되고 명령 기록에 남는다(U2).
func restore_orders(snap: Dictionary) -> void:
	battle.restore_orders(snap)

# ------------------------------------------------------------ 전대 세부 정보(선택 패널 펼침)
# 자기 진영 전대만 준다. 적 접촉은 안개 규칙(이름·역할·전력 구간만)이라, POC 규칙은 값이 없어 빈 사전이다.
const AMMO_LABEL := {"artillery": "포격", "line_fire": "직사", "intercept": "요격", "torpedo": "뇌격"}
func detail(id: int) -> Dictionary:
	var v = battle.by_id(id)
	if v == null or v.side != 0 or v.contact != "" or battle.sim.salvo == null:
		return {}
	var f = battle.sim.st.by_id(id)
	if f == null:
		return {}
	var d: Dictionary = {}
	for a in battle.ALLY_DEF:
		if a.get("squadron_id", "") == f.sq_id:
			d = a
	var grp := ""
	for g in ScenarioRoster.load_scenario().get("fleet_groups", []):
		if g.id == f.group_id:
			grp = g.name
	var n0 := 0
	for t in f.comp0:
		n0 += int(f.comp0[t])
	var r: Dictionary = combat.resources
	var vice = d.get("vice_commander", {})
	var hz := float(battle.sim.st.hz)
	return {
		"group": grp,
		"vice": vice.get("name", "") if vice is Dictionary else "",
		"staff": d.get("staff", []).map(func(p): return str(p.name)),
		"stats": f.stats,
		"morale_bp": f.morale_bp, "mstate": f.mstate,
		"hull": f.hull, "max_hull": f.max_hull, "stages": f.stages,
		"ammo": f.ammo,
		"energy": f.energy_m / 1000.0, "energy_max": float(r.energy_base) + float(r.energy_per_ship) * n0,
		"heat": f.heat_m / 1000.0, "heat_max": float(r.heat_base) + float(r.heat_per_ship) * n0,
		"speed": f.speed, "range": f.range_r,
		"formation": combat.formations.get(f.formation_id, {}).get("name", f.formation_id),
		"form_to": combat.formations.get(f.form_to, {}).get("name", "") if f.form_to != "" else "",
		"form_left_s": f.form_left / hz,
	}
