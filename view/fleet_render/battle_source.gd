class_name BattleSource
extends RefCounted

# 표현 계층이 전투 상태를 읽는 유일한 통로.
# 지금은 POC(FleetBattle3D.gd)의 Fleet 객체를 읽는다. M1에서 BattleProjection이 정해지면
# 이 파일만 고쳐 같은 모양의 사전을 돌려주면 된다.
#
# squadron 사전: {id, side, name, role, portrait, pos(px), heading, ships, max_ships, flagship,
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
		"id": f.id, "side": f.side, "name": f.fname, "role": f.role, "portrait": f.portrait,
		"pos": f.pos, "heading": f.heading, "ships": f.ships, "max_ships": f.max_ships,
		"flagship": f.is_flag, "dead": f.dead,
		"target_id": f.target.id if f.target else -1,
		"firing_at": f.fire_t.id if (f.fire_t and not f.fire_t.dead) else -1,
		"formation": f.form_id % battle.FORM_NAMES.size(),
		"formation_name": battle.FORM_NAMES[f.form_id % battle.FORM_NAMES.size()],
		"defense": f.defense, "charge_t": f.charge_t, "in_cmd": f.in_cmd,
		"missile_cd": f.missile_cd, "fighter_cd": f.fighter_cd,
		"speech": f.speech, "speech_t": f.speech_t,
		"has_move": f.has_move, "move_to": f.move_to, "lv": f.lv, "range": f.range_r,
	}

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
# 임시 판정이다. 코어의 "알림 분기"가 생기면 이 함수만 코어 판정으로 바꾼다.
# 안개가 생기면(M6, 리뷰 V-2) 적 전체가 아니라 **공개 투영의 접촉**(확인·추정)만 본다. 미탐지 적의 위치로
# 자동 ×4가 풀리면 안개가 샌다. 미탐지 적이 쏘면 그 사격 사건으로 조용한 구간이 끝난다.
func quiet() -> bool:
	if not battle.missiles.is_empty() or not battle.swarms.is_empty():
		return false
	var reach := maxf(battle.MISSILE_R, battle.FIGHTER_R) * ENGAGE_MARGIN
	for a in battle.fleets:
		if a.dead or a.side != 0:
			continue
		for b in battle.fleets:
			if b.dead or b.side == 0:
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
			if b.dead or b.side == 0:
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

# 시간 배율(선택 감속 ×0.2). POC는 dt로 움직이므로 엔진 시간 배율로 늦춘다. UI는 UiDraw.real_dt로 실제 시간을 쓴다.
func set_time_scale(k: float) -> void:
	Engine.time_scale = k

# 배속 설정. 표현 계층이 전투 시계를 바꾸는 유일한 통로다(POC는 프레임당 시뮬레이션 횟수).
func set_speed(n: int) -> void:
	battle.G.speed = n

# ------------------------------------------------------------ 규칙 값(화면 문구용)
# 화면의 효과 문구(측면·후면, 명령 설명)는 이 값으로 만든다(hud/ui_kit/rule_text.gd).
# set = "poc": 지금 돌아가는 POC 규칙. FleetBattle3D.gd의 리터럴과 같아야 한다(tests/rule_text.gd가 대조한다).
# 코어가 확정 규칙(v0.2: Q33 방향 = 명중률 보정, Q42 돌격 = 열 40%·사기 안정, 방어진형 삭제)으로 바뀌면
# 여기서 set = "v02"와 그 값을 돌려주고, 문구는 rule_text.gd의 v02 틀로 자동으로 바뀐다.
func rules() -> Dictionary:
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

# 지금 규칙에 있는 명령(진형·태세 탭 구성). v02에서는 "def"(방어진형)가 빠진다.
func has_command(id: String) -> bool:
	if id == "def":
		return rules().has("defense")
	return true

# 공격 방향: "front" | "side" | "rear" (표적 기준)
func attack_dir(att_id: int, tgt_id: int) -> String:
	var a = battle.by_id(att_id)
	var t = battle.by_id(tgt_id)
	if a == null or t == null:
		return "front"
	var m: float = battle.flank_mul(a, t)
	return "rear" if m > 1.45 else ("side" if m > 1.05 else "front")

# ------------------------------------------------------------ 세력(C-3)
# 세력 키: "shu"(촉) | "wei"(위) | "wu"(오). 지금 POC는 진영(side)만 있어 촉·위로 나눈다.
# faction_override는 미리보기·캡처용이다. 코어에 세력 값이 생기면 그 값을 읽는다.
var faction_override := {}

func faction(id: int) -> String:
	if faction_override.has(id):
		return faction_override[id]
	var f = battle.by_id(id)
	return "wei" if f and f.side == 1 else "shu"

# 지휘 상태(Q20, 리뷰 V-1): "direct"(직접 지휘 ●) | "delegated"(위임 ○) | ""(모름).
# 세력과 무관하다(유비 전대도 위임할 수 있고 손권 전대에도 직접 명령할 수 있다). 세력은 글리프가 맡는다.
# POC에는 위임 개념이 없어 ""를 돌려준다(표시하지 않는다). 코어의 지휘 상태가 생기면 이 함수만 고친다.
func command_mode(_id: int) -> String:
	return ""

# ------------------------------------------------------------ 함종 카운터(리뷰 C-1)
# 전대의 함종별 실제 척 수 [[함종 이름, 수], ...]. 코어가 시나리오 편성(ScenarioRoster)을 읽게 되면 그 카운터를 준다.
# POC에는 함종 카운터가 없다(함선 수 하나뿐). 화면 숫자는 코어 카운터만 쓰므로 빈 배열을 돌려준다.
func composition(_id: int) -> Array:
	return []

# ------------------------------------------------------------ 결정 분기(EXPERIENCE-DESIGN §5)
# 곧 분기(리뷰 V-4): 약 3초 전 예고. {"secs": 남은 게임 초, "pos": 관련 위치(전장 px)}. 없으면 {}.
# POC에는 분기가 없다. incoming_override는 미리보기·테스트용이다.
var incoming_override := {}

func decision_incoming() -> Dictionary:
	return incoming_override

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

# 스냅숏의 명령 상태로 되돌린다. POC 전용 쓰기 통로다.
# 코어에서는 "직전 상태로 돌아가는 새 명령"으로 기록해 결정론을 지킨다(U2). 그때 이 함수만 명령 발행으로 바꾼다.
func restore_orders(snap: Dictionary) -> void:
	for id in snap:
		var f = battle.by_id(id)
		if f == null or f.dead:
			continue
		var o: Array = snap[id]
		f.has_move = o[0]
		f.move_to = o[1]
		var t = battle.by_id(o[2]) if o[2] >= 0 else null
		f.target = t if (t and not t.dead) else null
		f.defense = o[3]
