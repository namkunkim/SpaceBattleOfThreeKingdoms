class_name BattleOutcome
extends RefCounted

# 전장 → 천하 지도 계약(docs/battle-core/WORLD-MAP-LINK.md §3).
# 천하 지도는 이 값으로 권역 색·결말 문장·후일담만 바꾸고 저장하지 않는다(캠페인 없음).
# 적벽 프로필 판은 Victory.settle 결산(st.result)을, POC 판(결산 없음)은 승패·종료 사유만 쓴다.

const KINDS := ["alliance_win", "alliance_limited", "cao_win"]

var kind := "cao_win"
var win := false
var limited := false
var reason := ""
var grade := ""            # 결정적 승리 | 우세 | 근소 우세 | 무승부 | 패배
var cao_status := ""       # killed | captured | severe | unhurt ("" = 결산 없음)
var liu_status := ""
var t_s := 0.0
var loss_pct := {"alliance": 0, "foe": 0}   # 시작 코스트 대비 잃은 비율(%)
var ending := ""           # EpilogueText.ENDINGS 키
var line := ""             # EpilogueText.LINES 키
var fingerprint := ""
var seed := 0
var mode := ""
var difficulty := ""
var settlement_id := ""
# The approved product outcome is handed directly from the host to the map.
var is_product_operation := false

static func from_operation(facts: Dictionary, brief: BattleBrief, clock_ms: int) -> BattleOutcome:
	if not facts.get("id") is String or facts.id.is_empty() \
			or facts.get("kind") not in ["objective_success", "withdrawal_success", "failure"] \
			or not facts.get("reason") is String or facts.reason.is_empty() or facts.get("clock_ms") != clock_ms:
		return null
	var o := BattleOutcome.new()
	o.settlement_id = facts.id
	o.kind = facts.kind
	o.reason = facts.reason
	o.win = o.kind != "failure"
	o.t_s = clock_ms / 1000.0
	o.seed = brief.seed
	o.mode = brief.mode
	var request := brief.operation_request()
	o.difficulty = request.difficulty
	o.is_product_operation = request == BattleBrief.Product.REQUEST
	return o

static func from_sim(sim: BattleSim, brief: BattleBrief) -> BattleOutcome:
	return from_facts(facts_from_sim(sim), brief)

# Capture the legacy simulation result while its owner still has exclusive access.
static func facts_from_sim(sim: BattleSim) -> Dictionary:
	var st := sim.st
	return {
		"win": st.win,
		"reason": st.end_reason,
		"t_s": st.clock_s(),
		"result": st.result.duplicate(true),
		"fingerprint": sim.fingerprint(),
	}

static func from_facts(facts: Dictionary, brief: BattleBrief) -> BattleOutcome:
	var o := BattleOutcome.new()
	o.seed = brief.seed if brief else 0
	o.mode = brief.mode if brief else ""
	o.difficulty = brief.difficulty if brief else ""
	o.win = facts.win
	o.reason = facts.reason
	o.t_s = facts.t_s
	o.fingerprint = facts.fingerprint
	var r: Dictionary = facts.result
	o.limited = bool(r.get("limited", false))
	o.kind = ("alliance_limited" if o.limited else "alliance_win") if o.win else "cao_win"
	if not r.is_empty():
		var cost: Dictionary = r.get("cost", {})
		o.loss_pct.alliance = _loss(cost.get("alliance", {}))
		o.loss_pct.foe = _loss(cost.get("foe", {}))
		var bp: Array = r.get("army_morale_bp", [0, 0])
		o.grade = grade_of(o.win, int(bp[0]) - int(bp[1]))
		o.cao_status = str(r.get("commanders", {}).get("foe", ""))
		o.liu_status = str(r.get("commanders", {}).get("alliance", ""))
	else:
		o.grade = "승리" if o.win else "패배"
	o.ending = ending_of(o)
	o.line = line_of(o)
	return o

static func _loss(c: Dictionary) -> int:
	var o := int(c.get("original", 0))
	if o <= 0:
		return 0
	return clampi(roundi(100.0 * (o - int(c.get("remaining", o))) / o), 0, 100)

# 제안서 §6.3: 군 사기 격차(bp ÷ 100) 60 이상 결정적 승리, 30~59 우세, 10~29 근소 우세, 10 미만 무승부.
static func grade_of(win: bool, bp_gap: int) -> String:
	if not win:
		return "패배"
	var g := bp_gap / 100
	if g >= 60:
		return "결정적 승리"
	if g >= 30:
		return "우세"
	if g >= 10:
		return "근소 우세"
	return "무승부"

# 결말 문장(NARRATIVE §5 D). 조건이 겹치면 위에서부터 먼저 맞는 것.
static func ending_of(o: BattleOutcome) -> String:
	if not o.win:
		match o.reason:
			"liu_flagship_lost":
				return "J-D8"
			"time_limit", "simultaneous":
				return "J-D10"
		return "J-D7"
	if o.limited:
		return "J-D6"
	match o.reason:
		"cao_flagship_lost":
			return "J-D2"
		"cao_morale_collapse":
			return "J-D3" if o.grade == "결정적 승리" else "J-D4"
		"time_limit":
			return "J-D5"
	return "J-D1"

# 후일담 한 줄: 조건이 맞는 것 중 시드로 하나(NARRATIVE §6). 결정적이다.
static func line_of(o: BattleOutcome) -> String:
	var c: Array = []
	if not o.win:
		c = ["E11"]
	else:
		if o.cao_status == "" or o.cao_status == "unhurt" or o.cao_status == "severe":
			c.append_array(["E1", "E2", "E4"])   # 조조 도주
		if not o.limited:
			c.append_array(["E5", "E6"])
		if o.liu_status != "killed" and o.liu_status != "captured":
			c.append("E9")
	return c[absi(o.seed) % c.size()]

func ending_text() -> String:
	var s: String = EpilogueText.ENDINGS.get(ending, "")
	s = s.replace("{조조_상태}", "알 수 없다" if cao_status == "" else EpilogueText.CAO_STATUS.get(cao_status, cao_status))
	s = s.replace("{손실_적}", "전력의 %d%%" % loss_pct.foe)
	s = s.replace("{시각}", "교전 %d분" % int(t_s / 60.0))
	return s

func line_text() -> Array:
	return EpilogueText.LINES.get(line, ["", ""])

func to_dict() -> Dictionary:
	var result := {"kind": kind, "win": win, "limited": limited, "reason": reason, "grade": grade, "cao_status": cao_status,
		"liu_status": liu_status, "t_s": t_s, "loss_pct": loss_pct.duplicate(), "ending": ending, "line": line,
		"fingerprint": fingerprint, "seed": seed, "mode": mode, "difficulty": difficulty}
	if not settlement_id.is_empty():
		result.settlement_id = settlement_id
	return result

static func from_dict(d: Dictionary) -> BattleOutcome:
	var o := BattleOutcome.new()
	for k in ["kind", "reason", "grade", "cao_status", "liu_status", "ending", "line", "fingerprint", "mode", "difficulty"]:
		o.set(k, str(d.get(k, "")))
	o.settlement_id = str(d.get("settlement_id", ""))
	o.win = bool(d.get("win", false))
	o.limited = bool(d.get("limited", false))
	o.t_s = float(d.get("t_s", 0.0))
	o.seed = int(d.get("seed", 0))
	var lp: Dictionary = d.get("loss_pct", {})
	o.loss_pct = {"alliance": int(lp.get("alliance", 0)), "foe": int(lp.get("foe", 0))}
	return o
