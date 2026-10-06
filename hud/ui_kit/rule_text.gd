class_name RuleText
extends RefCounted

# 규칙 값 → 화면 문구. 값은 BattleSource.rules()에서만 읽는다.
# set "poc": 지금 동작(측면·배후 = 화력 배율, 방어진형 있음).
# set "v02": 확정 규칙 틀(Q33 측면 명중 +10%p·적 사기 타격 ×1.25, 후면 +25%p·×1.5 / Q42 돌격 / 방어진형 삭제).

static func _pct(m: float) -> String:
	return "%+d%%" % roundi((m - 1.0) * 100.0)

static func _x(m: float) -> String:
	return "×%s" % String.num(m, 2).trim_suffix("0").trim_suffix(".")

# 정보 패널 교전 칩의 꼬리말: "· 측면 +30%" 등. 정면이면 빈 문자열.
static func flank_chip(r: Dictionary, dir: String) -> String:
	if dir == "front":
		return ""
	var fl: Dictionary = r.flank
	var name := "측면" if dir == "side" else ("배후" if r.set == "poc" else "후면")
	if fl.model == "damage":
		return " · %s %s" % [name, _pct(fl[dir])]
	return " · %s 명중 %+d%%p" % [name, int(fl[dir].hit)]

# 브리핑의 규칙 한 줄
static func flank_rule(r: Dictionary) -> String:
	var fl: Dictionary = r.flank
	if fl.model == "damage":
		return "측면 공격 화력 %s, 배후 공격 %s" % [_pct(fl.side), _pct(fl.rear)]
	return "측면 명중 %+d%%p·적 사기 타격 %s, 후면 %+d%%p·%s" % [int(fl.side.hit), _x(fl.side.morale), int(fl.rear.hit), _x(fl.rear.morale)]

# 지휘 범위 밖 불이익: POC는 화력 배율, v02는 명중률 −N%p.
static func out_of_cmd(r: Dictionary) -> String:
	if r.set == "poc":
		return "화력 %s" % _pct(r.out_of_cmd_fire).replace("-", "−")
	return "명중률 −%d%%p" % int(r.out_of_cmd_hit)

static func cmd_range_rule(r: Dictionary) -> String:
	return "기함 지휘 범위 밖의 함대는 %s" % out_of_cmd(r)

static func cost_rule(r: Dictionary) -> String:
	if r.set != "poc":
		return "돌격: 열 용량 %d%%, 사기 %d%% 이상일 때만" % [roundi(r.charge.heat * 100.0), roundi(r.charge.get("min_morale", 0.6) * 100.0)]
	return "지휘력으로 미사일(%d)·함재기(%d)·돌격(%d) 사용" % [r.missile.cost, r.fighter.cost, r.charge.cost]

static func defense_rule(r: Dictionary) -> String:
	if not r.has("defense"):
		return ""
	return "방어진형: 받는 피해 %s, 화력·속도 감소" % _pct(r.defense.taken).replace("-", "−")

# 명령 설명: {desc, fx:[[이름, 값, 좋음?]], foot}
static func cmd(r: Dictionary, id: String) -> Dictionary:
	match id:
		"def":
			if not r.has("defense"):
				return {"desc": "방어진형은 없습니다. 진형 탭의 방원진을 쓰십시오."}
			var d: Dictionary = r.defense
			return {"desc": "진형을 좁혀 피해를 줄입니다. 다시 누르면 풉니다.", "fx": [["받는 피해", _x(d.taken), true], ["화력", _x(d.fire), false], ["속도", _x(d.speed), false]]}
		"charge":
			var c: Dictionary = r.charge
			if r.set == "poc":
				var fx := [["화력", _x(c.fire), true], ["속도", _x(c.speed), true]]
				if c.get("ends_defense", false):
					fx.append(["방어진형", "해제", false])
				return {"desc": "가장 가까운 적에게 돌입합니다." + (" 방어진형은 풀립니다." if c.get("ends_defense", false) else ""), "fx": fx, "foot": "지속 %d초 · 길게 눌러 확정" % int(c.dur)}
			return {"desc": "가장 가까운 적에게 돌입합니다. 열 용량의 %d%%를 쓰고, 사기가 안정일 때만 쓸 수 있습니다." % roundi(c.heat * 100.0), "fx": [["열 용량", "%d%%" % roundi(c.heat * 100.0), false]], "foot": "길게 눌러 확정"}
		"rally":
			return {"desc": "선택한 함대가 기함 주위로 모여 지휘 범위 안으로 들어옵니다. 범위 밖 함대는 %s입니다." % out_of_cmd(r)}
		"retreat":
			return {"desc": "가장 가까운 적의 반대쪽으로 전선을 물립니다.", "foot": "길게 눌러 확정"}
		"missile":
			var m: Dictionary = r.missile
			return {"desc": "사거리 안의 적에게 유도 미사일 %d발을 일제 발사합니다." % m.n, "fx": [["사거리", str(int(m.range)), true]], "foot": "재장전 %d초" % int(m.cd)}
		"fighter":
			var f: Dictionary = r.fighter
			return {"desc": "함재기 편대를 발진시켜 %d초 동안 적을 근접 공격합니다." % int(f.dur), "fx": [["작전 반경", str(int(f.range)), true]], "foot": "정비 %d초" % int(f.cd)}
	return {}
