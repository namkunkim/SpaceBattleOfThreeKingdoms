class_name DecisionBoard
extends RefCounted

# M7 결정 카드(제안서 §5.5, 리뷰 V-3·V-4). 코어는 카드의 상태와 시간만 가진다. 대사·화면은 UI 몫이다.
# 카드 수명: 예고(precursor_s) → 열림 → 응답(decide 명령) 또는 time_game_s 뒤 추천안 적용("위임 처리").
# 시간은 게임 시계다. 코어는 멈추지 않는다(입문 정지·표준 ×0.2는 호스트가 속도로 만든다).
# 카드 종류(M7): morale_crisis(연합 군 사기가 위기 임계 아래로), pursuit(확인한 적 전대가 퇴각 상태로).
# 화공·의심 카드는 M9. 응답은 지휘관 AI의 일시 가중(bias_mod)·추격 표적으로 반영된다.

var sim: BattleSim
var cfg: Dictionary          # realtime_rules.decision_cards
var A: Dictionary            # ai.decisions
var cards: Array[Dictionary] = []   # {id, kind, ref, open_tick, deadline_tick, options, rec}
var done: Array[Dictionary] = []    # 통계: {id, kind, open_tick, tick, option, by}
var _seq := 1
var _crisis_armed := true
var _seen_retreat: Dictionary = {}

func _init(s: BattleSim, decision_cfg: Dictionary, ai_cfg: Dictionary) -> void:
	sim = s
	cfg = decision_cfg
	A = ai_cfg

func _ticks(sec: float) -> int:
	return BattleRules.ticks(sec, sim.st.hz)

# ============================================================ 질의
# 투영용. 열린 카드와 곧 열릴(예고 중) 카드를 가른다.
func pending() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var st := sim.st
	for c in cards:
		if st.tick >= c.open_tick:
			out.append({"id": c.id, "kind": c.kind, "ref": c.ref, "options": c.options.duplicate(true), "rec": c.rec,
				"time_left": float(c.deadline_tick - st.tick) / st.hz, "time_total": float(cfg.time_game_s)})
	return out

func upcoming() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var st := sim.st
	for c in cards:
		if st.tick < c.open_tick:
			out.append({"id": c.id, "kind": c.kind, "eta_s": float(c.open_tick - st.tick) / st.hz})
	return out

func fingerprint() -> String:
	var parts := PackedStringArray()
	for c in cards:
		parts.append("%d.%s.%d.%d" % [c.id, c.kind, c.open_tick, c.deadline_tick])
	return ",".join(parts)

# ============================================================ 한 틱
func step() -> void:
	var st := sim.st
	_detect_crisis()
	_detect_pursuit()
	for c in cards.duplicate():
		if st.tick == c.open_tick:
			sim.emit("decision_open", -1, int(c.ref), Vector2.ZERO, {"id": c.id, "kind": c.kind})
		if st.tick >= c.deadline_tick:
			resolve(c.id, c.rec, "delegate")

func _open(kind: String, ref: int, options: Array, rec: String) -> void:
	var st := sim.st
	var open := st.tick + _ticks(float(cfg.precursor_s))
	cards.append({"id": _seq, "kind": kind, "ref": ref, "open_tick": open, "deadline_tick": open + _ticks(float(cfg.time_game_s)), "options": options, "rec": rec})
	_seq += 1

func _detect_crisis() -> void:
	var m := sim.morale
	if m == null:
		return
	var bp := m.army_bp(0)
	if bp < m.crisis_bp():
		if _crisis_armed:
			_crisis_armed = false
			_open("morale_crisis", -1, [{"id": "defend"}, {"id": "counter"}], "defend")   # 전황 반응: 아군 사기 위기는 방어 가중(§5.2)
	elif bp >= m.crisis_bp() + int(A.crisis.rearm_gap_bp):
		_crisis_armed = true

func _detect_pursuit() -> void:
	for f in sim.st.fleets:
		if f.side != 1 or f.dead or f.out != "" or f.mstate != "retreat" or _seen_retreat.has(f.id):
			continue
		# 화면에서 보이는 퇴각만 묻는다: 확인 접촉이어야 카드가 정보를 새지 않는다
		if sim.detect and sim.detect.state(0, f.id) != "confirmed":
			continue
		_seen_retreat[f.id] = true
		var rec := "pursue" if sim.morale and sim.morale.army_bp(0) >= int(A.pursuit.recommend_min_army_bp) else "hold"
		_open("pursuit", f.id, [{"id": "pursue"}, {"id": "hold"}], rec)

# ============================================================ 응답
func card(id: int) -> Dictionary:
	for c in cards:
		if c.id == id:
			return c
	return {}

# by: "player" | "delegate". 열리지 않은(예고 중) 카드는 응답할 수 없다. 성공하면 ""
func resolve(id: int, option: String, by: String) -> String:
	var c := card(id)
	if c.is_empty():
		return "no_decision"
	if sim.st.tick < c.open_tick:
		return "decision_not_open"
	var ok := false
	for o in c.options:
		if o.id == option:
			ok = true
	if not ok:
		return "bad_option"
	cards.erase(c)
	_apply(c, option)
	done.append({"id": c.id, "kind": c.kind, "open_tick": c.open_tick, "tick": sim.st.tick, "option": option, "by": by})
	sim.emit("decision_resolved", -1, int(c.ref), Vector2.ZERO, {"id": c.id, "kind": c.kind, "option": option, "by": by})
	return ""

func _apply(c: Dictionary, option: String) -> void:
	var st := sim.st
	var mods := {"defend": -1.0, "counter": 1.0, "pursue": 1.0, "hold": 0.0}
	var d: Dictionary = A.crisis if c.kind == "morale_crisis" else A.pursuit
	var foe := st.by_id(int(c.ref)) if c.kind == "pursuit" else null
	for f in st.alive(0):
		if f.control != "delegate":
			continue   # 직접 지휘 전대는 AI 가중을 받지 않는다
		if foe and f.pos.distance_to(foe.pos) > float(d.radius):
			continue
		f.bias_mod = float(mods[option]) * float(d.bias_mod)
		f.bias_until = st.tick + _ticks(float(d.effect_s))
		if option == "pursue" and foe:
			f.pursue_id = foe.id
			f.pursue_until = f.bias_until
