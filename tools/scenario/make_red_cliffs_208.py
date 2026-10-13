"""적벽 시나리오 데이터 생성기. data/scenarios/red_cliffs_208_realtime.json을 만든다.

본편 characters.json(통솔)과 red-cliffs-demo-setup.json(함종 비용)을 읽어 비용과 지휘 한도를 계산한다.
실행: python make_red_cliffs_208.py
"""
import json, math, os

CHAR = {c["id"]: c for c in json.load(open(r"C:\WorkSpace\Seonghanji\data\characters.json", encoding="utf-8"))}
SETUP = json.load(open(r"C:\WorkSpace\Seonghanji\data\red-cliffs-demo-setup.json", encoding="utf-8"))
COST = {s["id"]: s["unit_cost"] for s in SETUP["ship_types"]}
EQ = {e["id"]: e["unit_cost"] for e in SETUP["ship_types"][7]["mission_equipment"]}


SHIP_SCALE = 3   # 함종별 척 수 배율(2026-10-09 사용자 결정: 3배 확대). 아래 편성표는 1배 값이다
LIMIT_SCALE = SHIP_SCALE   # 지휘 한도도 같은 배율로 올려 한도 초과 구간을 1배 때와 같게 둔다(combat_m3 command.limit_*)


def C(t, n, eq=None):
    d = {"ship_type_id": t, "count": n * SHIP_SCALE}
    if eq:
        d["mission_equipment_id"] = eq
    return d


def P(cid):
    c = CHAR[cid]
    st = c["stats"]
    traits = [t[t.index("「") + 1:t.index("」")] for t in c.get("traits", []) if "「" in t]
    return {"id": cid, "name": c["name"], "command": st["통솔"], "might": st["무력"], "intellect": st["지력"], "politics": st["정치"], "charm": st["매력"], "traits": traits}


def sq(id, fac, name, cmd, vice, staff, flag, pos, frm, comp, basis, **kw):
    d = {"id": id, "faction_id": fac, "name": name, "commander": P(cmd),
         "vice_commander": P(vice) if vice else None, "staff": [P(s) for s in staff],
         "flagship": flag, "initial_position": pos, "formation_id": frm, "composition": comp}
    d.update(kw)
    d["historical_basis"] = basis
    return d


SQUADRONS = [
    sq("RC-LIU-SQ-01", "liu_bei", "유비 본대", "CHR-0128", "CHR-0130", ["CHR-0134"], True, [310, 620], "FRM-03",
       [C("SHP-04", 4), C("SHP-05", 1), C("SHP-07", 2), C("SHP-08", 6, "FAST-EQ-RECON")],
       "유비는 번구(樊口)에서 주유와 합류했다. 장비·제갈량의 전투 중 역할은 기록이 없어 본대 소속으로 둔다. 별도 정찰 고속전대는 두지 않고(R5) 정찰 고속정 6척을 본대에 편성한다. 조운의 적벽 전투 기록은 없다."),
    sq("RC-LIU-SQ-02", "liu_bei", "관우 수군", "CHR-0107", None, [], False, [430, 600], "FRM-01",
       [C("SHP-03", 2), C("SHP-04", 3), C("SHP-07", 2)],
       "『삼국지』 제갈량전: 관우의 수군 정예 1만."),
    sq("RC-LIU-SQ-03", "liu_bei", "유기 강하군", "CHR-0325", None, [], False, [230, 700], "FRM-03",
       [C("SHP-03", 1), C("SHP-04", 3), C("SHP-05", 1)],
       "『삼국지』 제갈량전: 유기가 모은 강하의 병사 1만 이상. 유기는 하구(夏口)를 지켰다."),
    sq("RC-SUN-SQ-01", "sun_quan", "주유 중군", "CHR-0211", "CHR-0185", ["CHR-0186"], True, [420, 470], "FRM-02",
       [C("SHP-01", 1), C("SHP-03", 3), C("SHP-04", 5), C("SHP-06", 2), C("SHP-07", 3)],
       "주유는 좌독(左督), 노숙은 찬군교위(贊軍校尉)로 종군했다. 감녕은 주유를 따라 오림에서 싸웠다(감녕전)."),
    sq("RC-SUN-SQ-02", "sun_quan", "정보 우군", "CHR-0207", "CHR-0212", ["CHR-0199"], False, [470, 370], "FRM-01",
       [C("SHP-03", 2), C("SHP-04", 4), C("SHP-05", 1), C("SHP-07", 2)],
       "정보는 우독(右督). 주태·여몽은 주유·정보와 함께 조조를 오림에서 깨뜨렸다(주태전·여몽전)."),
    sq("RC-SUN-SQ-03", "sun_quan", "황개 화공대", "CHR-0217", "CHR-0216", ["CHR-0187"], False, [380, 330], "FRM-05",
       [C("SHP-04", 2), C("SHP-07", 1), C("SHP-08", 8, "FAST-EQ-TORPEDO")],
       "황개가 '조조군 배가 머리와 꼬리를 잇대었으니 불태우고 달아날 수 있다'고 건의하고 몽충·투함으로 화공했다(주유전). 한당·능통도 오림에서 싸웠다(한당전·능통전). 연쇄 폭발 작전의 폭발정을 이 전대가 운용한다."),
    sq("RC-CAO-SQ-01", "cao_cao", "조조 중군", "CHR-0034", "CHR-0047", ["CHR-0031", "CHR-0001"], True, [1460, 330], "FRM-04",
       [C("SHP-01", 2), C("SHP-03", 4), C("SHP-04", 8), C("SHP-05", 2), C("SHP-06", 2), C("SHP-07", 2), C("SHP-08", 6, "FAST-EQ-INTERCEPT")],
       "허저는 늘 조조를 호위했다. 정욱은 손권이 유비를 도울 것을 예견했고(정욱전), 가후는 동쪽 원정을 말렸다(가후전).",
       morale_group="northern", deploy_delay_s=180),
    sq("RC-CAO-SQ-02", "cao_cao", "조인 선봉", "CHR-0033", None, [], False, [1330, 420], "FRM-01",
       [C("SHP-01", 1), C("SHP-03", 4), C("SHP-04", 10), C("SHP-07", 3)],
       "조인은 형주 평정에 종군하고 전투 뒤 강릉을 지켰다(조인전).",
       morale_group="northern", deploy_delay_s=0),
    sq("RC-CAO-SQ-03", "cao_cao", "서황 별군", "CHR-0017", "CHR-0009", [], False, [1530, 470], "FRM-03",
       [C("SHP-02", 2), C("SHP-03", 5), C("SHP-04", 9), C("SHP-05", 1)],
       "서황은 형주 정벌에 종군하고 뒤에 조인과 함께 강릉에서 주유를 막았다(서황전). 만총도 형주 정벌에 종군했다(만총전).",
       morale_group="northern", deploy_delay_s=180),
    sq("RC-CAO-SQ-04", "cao_cao", "형주 수군 갑", "CHR-0010", None, [], False, [1250, 150], "FRM-04",
       [C("SHP-03", 4), C("SHP-04", 8), C("SHP-05", 1), C("SHP-07", 2)],
       "문빙은 유종과 함께 항복해 중용되었다(문빙전). 주유는 형주 항복군 7~8만이 '아직 의심을 품고 있다'고 보았다(『강표전』).",
       morale_group="jing_navy", deploy_delay_s=0),
    sq("RC-CAO-SQ-05", "cao_cao", "형주 수군 을", "CHR-0330", "CHR-0329", [], False, [1330, 190], "FRM-03",
       [C("SHP-03", 3), C("SHP-04", 6), C("SHP-05", 1)],
       "채모는 유종의 항복을 이끌었고 정사에서는 처형되지 않았다. 채모·장윤의 처형은 『삼국지연의』의 장간 이야기다.",
       morale_group="jing_navy", deploy_delay_s=180),
    sq("RC-CAO-SQ-06", "cao_cao", "조순 호표 고속대", "CHR-0084", None, [], False, [1400, 560], "FRM-05",
       [C("SHP-07", 6), C("SHP-08", 10, "FAST-EQ-INTERCEPT")],
       "조순은 호표기를 이끌고 장판에서 유비를 추격했다(조순전). 그 정예 기동 부대를 고속 요격 전대로 옮긴다.",
       morale_group="northern", deploy_delay_s=360),
    sq("RC-CAO-SQ-07", "cao_cao", "조홍 후군", "CHR-0036", None, [], False, [1580, 250], "FRM-03",
       [C("SHP-03", 3), C("SHP-04", 6), C("SHP-07", 2)],
       "조홍의 적벽 종군은 기록이 분명하지 않다. 상급 이상에서만 배치하는 후군이다.",
       morale_group="northern", deploy_delay_s=360),
]


# 편성 화면용 세력별 가용 장수(Q73~Q77): 본편 assignments.json SCN-03(적벽 전야) "소속" + 이 시나리오 전대 지휘부, 불참(not_deployed) 제외.
# 시나리오에 나오는 인물은 시나리오 세력이 이긴다(예: 유기는 본편 유표 진영이지만 유비군).
UPSTREAM_FACTION = {"촉": "liu_bei", "오": "sun_quan", "위": "cao_cao"}
ASSIGN = json.load(open(r"C:\WorkSpace\Seonghanji\data\assignments.json", encoding="utf-8"))


def available_officers(squadrons, not_deployed):
    side = {}
    for a in ASSIGN:
        if a["scenario"] == "SCN-03" and a["status"] == "소속" and a["faction"] in UPSTREAM_FACTION:
            side[a["character"]] = UPSTREAM_FACTION[a["faction"]]
    for s in squadrons:
        for o in [s["commander"], s.get("vice_commander")] + s.get("staff", []):
            if o:
                side[o["id"]] = s["faction_id"]
    out = {}
    for cid in sorted(side):
        if cid not in not_deployed:
            out.setdefault(side[cid], []).append(P(cid))
    return out


def cost(comp):
    return sum(c["count"] * (COST[c["ship_type_id"]] + EQ.get(c.get("mission_equipment_id", ""), 0)) for c in comp)


DIFF = {
    "입문": {"target_cost_ratio": 1.47,
           "start_morale_bp": {"northern": 8000, "jing_navy": 6000},
           "ai": {"think_depth": 1, "mistake_bp": 2500, "reaction_s": 120, "chain_risk_response": False, "chain_detect_mean_s": None, "suspicion_per_s": 0.4},
           "note": "역병과 원정 피로가 크고 형주 수군이 훈련되지 않았다. 조조는 밀집(연환)을 풀지 않는다."},
    "표준": {"target_cost_ratio": 1.59,
           "start_morale_bp": {"northern": 8000, "jing_navy": 6500},
           "ai": {"think_depth": 2, "mistake_bp": 1000, "reaction_s": 60, "chain_risk_response": True, "chain_detect_mean_s": 60, "suspicion_per_s": 0.8},
           "note": "본편 데모의 보통 난이도에 해당한다."},
    "상급": {"target_cost_ratio": 2.14,
           "start_morale_bp": {"northern": 9500, "jing_navy": 7500},
           "ai": {"think_depth": 3, "mistake_bp": 300, "reaction_s": 0, "chain_risk_response": True, "chain_detect_mean_s": 20, "suspicion_per_s": 1.5},
           "note": "본편 정본의 동원비 2.20배."},
    "극한": {"target_cost_ratio": 2.14,
           "start_morale_bp": {"northern": 10000, "jing_navy": 9000},
           "ai": {"think_depth": 3, "mistake_bp": 0, "reaction_s": 0, "chain_risk_response": True, "chain_detect_mean_s": 10, "suspicion_per_s": 2.0},
           "note": "역병 없음, 형주 수군 정상 훈련. 규모는 상급과 같고 정보 이점은 없다."},
}
ORDER = ["입문", "표준", "상급", "극한"]


NOT_DEPLOYED = {"sun_quan": [{"id": "CHR-0194", "name": "손권", "reason": "시상(柴桑)에 머물렀다"},
                             {"id": "CHR-0214", "name": "태사자", "reason": "건창에서 유반을 막았다"}],
                "cao_cao": [{"id": "CHR-0021", "name": "악진", "reason": "양양에 주둔"},
                            {"id": "CHR-0026", "name": "장료", "reason": "장사(長社)에 주둔"},
                            {"id": "CHR-0023", "name": "우금", "reason": "208년 적벽 종군 기록이 없다"}]}
POOL = available_officers(SQUADRONS, {x["id"] for v in NOT_DEPLOYED.values() for x in v})


def limit(cmd):
    return (40 + 2 * cmd) * LIMIT_SCALE


# Q80·Q81 자동 편성(Organization.auto_fill)과 같은 제독: 기함은 고정, 나머지 함대는 남은 가용 장수 중 통솔 순(같으면 ID 순).
# 함대 순서대로 한도가 내려간다. 모든 함대가 한도까지 찬다고 보고(Q80) 세력 비용 합 = 한도 합이다.
def auto_limits(fid, n):
    flag = next(s["commander"] for s in SQUADRONS if s["faction_id"] == fid and s["flagship"])
    rest = sorted((o for o in POOL[fid] if o["id"] != flag["id"]), key=lambda o: (-o["command"], o["id"]))
    return [limit(flag["command"])] + [limit(o["command"]) for o in rest[:n - 1]]


# P10b(D2): 유비 함대를 4개로 고정해 계산한다(조운 정찰대 폐지 전 연합 7함대 한도 합 4698). 함대 수가 줄어도 Q82 조조 함대 수(입문 11·표준 12·상급/극한 16)를 유지한다.
ALLY_FLEETS = {"liu_bei": 4, "sun_quan": sum(1 for s in SQUADRONS if s["faction_id"] == "sun_quan")}
ALLY_LIMIT = sum(sum(auto_limits(f, n)) for f, n in ALLY_FLEETS.items())
assert ALLY_LIMIT == 4698, ALLY_LIMIT

# Q82: 조조의 수적 우위 = 함대 수. 난이도마다 조조 함대 앞에서부터 cao_fleets개를 배치하고, 마지막 함대만 한도 × cao_last_fill_bp까지 채워
# 조조 비용 합 / 연합 비용 합을 target_cost_ratio에 맞춘다(함대 하나가 비율을 약 0.13씩 바꿔 함대 수만으로는 ±0.05를 못 맞춘다, 2026-10-10 사용자 결정).
CAO_LIMITS = auto_limits("cao_cao", len(POOL["cao_cao"]))
for d in DIFF.values():
    want = d["target_cost_ratio"] * ALLY_LIMIT
    acc = 0
    for i, lim in enumerate(CAO_LIMITS):
        if acc + lim >= want:
            d["cao_fleets"] = i + 1
            d["cao_last_fill_bp"] = round((want - acc) * 10000 / lim)
            break
        acc += lim
    d["cao_cost_at_limits"] = round(acc + lim * d["cao_last_fill_bp"] / 10000)

# 조조 추가 함대 슬롯(정사 7함대 뒤). 제독 = 시나리오 함대에 없는 조조 가용 장수 중 통솔 순(같으면 ID 순). 자동 편성은 제독을 다시 고른다.
# 위치: 기존 조조 함대 근처 격자에서 모든 함대와 90 이상 떨어지고 전장 가장자리·조조 탈출 지점에서 떨어진 칸, 조조 중군에 가까운 순
BOUNDS = [0, 0, 1600, 900]   # 격자(x 1240~1560, y 80~820)는 이 안이다
CAO_SQ = [s for s in SQUADRONS if s["faction_id"] == "cao_cao"]
used = {o["id"] for s in SQUADRONS for o in [s["commander"], s.get("vice_commander")] + s.get("staff", []) if o}
spare = sorted((o for o in POOL["cao_cao"] if o["id"] not in used), key=lambda o: (-o["command"], o["id"]))
assert len(POOL["cao_cao"]) >= 2 * max(d["cao_fleets"] for d in DIFF.values()), "조조 가용 장수 < 함대 수 × 2(제독·부제독)"
taken = [s["initial_position"] for s in SQUADRONS]
cells = sorted(([x, y] for x in range(1240, 1561, 80) for y in range(80, 821, 80)),
               key=lambda q: (math.dist(q, CAO_SQ[0]["initial_position"]), q))
for i in range(max(d["cao_fleets"] for d in DIFF.values()) - len(CAO_SQ)):
    pos = next(q for q in cells if all(math.dist(q, t) >= 90 for t in taken) and math.dist(q, [1600, 300]) >= 150)
    taken.append(pos)
    o = spare[i]
    SQUADRONS.append(sq("RC-CAO-SQ-%02d" % (len(CAO_SQ) + i + 1), "cao_cao", "%s 증원군" % o["name"], o["id"], None, [], False, pos, "FRM-03",
                        [C("SHP-03", 3), C("SHP-04", 6), C("SHP-07", 2)],
                        "Q82 추가 함대: 조조의 수적 우위를 함대 수로 맞춘다(게임 수치). 편성은 조홍 후군과 같은 틀이다.",
                        morale_group="northern", deploy_delay_s=360, historical=False))

# 화면 틀이 "%s 함대"라 이름이 "함대"로 끝나면 "○○ 함대 함대"가 된다(REVIEW-O5 #1)
assert not any(s["name"].endswith("함대") for s in SQUADRONS)

for s in SQUADRONS:
    s["declared_total_cost"] = cost(s["composition"])
    s["command_limit"] = limit(s["commander"]["command"])


def apply_difficulty(squadrons, diff):
    """난이도의 배치(difficulty_policy.cao_scale_rule): 조조 함대는 앞에서부터 cao_fleets개. 연합은 그대로."""
    p = DIFF[diff]
    out = []
    n = 0
    for s in squadrons:
        if s["faction_id"] != "cao_cao":
            out.append(dict(s, start_morale_bp=10000))
            continue
        n += 1
        if n <= p["cao_fleets"]:
            out.append(dict(s, start_morale_bp=p["start_morale_bp"][s["morale_group"]]))
    return out


# P8-0 장수 특기(Q88~Q91, 설계 docs/battle-core/SPECIAL-SKILLS.md). 모든 수치는 제안값이다.
# 효과 키와 AI 조건 문법은 SPECIAL-SKILLS.md §2·§4. 기간은 일제사격 주기(60초) 단위로 잡았다.
SKILL_TYPES = [
    {"id": "SK-T-FIRE", "type": "firepower", "name": "맹공", "target": "self", "duration_s": 120,
     "effects": {"damage_mul_bp": 11500},
     "ai_when": {"all": [{"enemy_in_band": "engagement"}]},
     "text": "{trait} — 120초 동안 함대의 모든 무장 피해 +15%."},
    {"id": "SK-T-GUARD", "type": "defense", "name": "견수", "target": "self", "duration_s": 120,
     "effects": {"damage_taken_mul_bp": 8000},
     "ai_when": {"all": [{"self_hull_below_bp": 7000}, {"enemy_in_band": "engagement"}]},
     "text": "{trait} — 120초 동안 함대가 받는 사격 피해 −20%."},
    {"id": "SK-T-MOVE", "type": "maneuver", "name": "질주", "target": "self", "duration_s": 60,
     "effects": {"speed_mul_bp": 13000, "transition_mul_bp": 5000},
     "ai_when": {"any": [{"self_retreating": True}, {"self_morale_below_bp": 4500}]},
     "text": "{trait} — 60초 동안 이동 속도 +30%, 진형 전환 시간 절반."},
    {"id": "SK-T-MORALE", "type": "morale", "name": "격려", "target": "self", "duration_s": 120,
     "effects": {"morale_bp": 800, "morale_loss_mul_bp": 7000},
     "ai_when": {"all": [{"self_morale_below_bp": 5000}]},
     "text": "{trait} — 함대 사기 즉시 +8, 120초 동안 사기 감소 −30%."},
    {"id": "SK-T-DISRUPT", "type": "disrupt", "name": "교란", "target": "enemy_fleet", "radius": 260, "duration_s": 60, "target_pick": {"from": "confirmed_enemy_fleets", "by": "nearest", "tie": "id"},
     "effects": {"morale_bp": -800, "hit_bp": -800},
     "requires": {"enemy_within": 260},
     "ai_when": {"all": [{"enemy_in_band": "barrage"}]},
     "text": "{trait} — 260 안의 확인된 적 함대 하나: 사기 즉시 −8, 60초 동안 명중률 −8%p."},
    {"id": "SK-T-SCOUT", "type": "detection", "name": "간파", "target": "self", "duration_s": 120,
     "effects": {"sensor_mul_bp": 15000, "reveal_radius": 400},
     "ai_when": {"all": [{"estimated_within": 400}]},
     "text": "{trait} — 120초 동안 센서 +50%, 400 안의 적 접촉을 확인 상태로 올린다."},
    {"id": "SK-T-SUPPLY", "type": "supply", "name": "조달", "target": "self", "duration_s": 0,
     "effects": {"charges_add": {"artillery": 1}},
     "requires": {"charges_below_base": "artillery"},
     "ai_when": {"all": [{"self_charges_zero": "artillery"}]},
     "text": "{trait} — 미사일 사용 횟수 즉시 +1(기본 3회 상한, 보급함 재고 소모 없음)."},
]
SKILL_TYPE_BY_TYPE = {t["type"]: t["id"] for t in SKILL_TYPES}

# 본편 combat.md §9 발동 시점이 있는 12종(Q88). relation = 이미 코어에 있는 규칙과의 관계(중복 효과 없음)
SKILL_UNIQUE = [
    {"id": "SK-U-GUANYU", "trait": "만인지적", "officer": "CHR-0107", "name": "만인지적", "target": "self", "duration_s": 60,
     "effects": {"assault_bp": 3000, "assault_cd_reset": True, "note": "재사용 대기 60초 = 지속 60초라 최대 2회 시도(의도)"},
     "requires": {"has_ship_type": "SHP-01"},
     "ai_when": {"all": [{"enemy_flagship_within": 100}]},
     "relation": "combat.assault.elite_ids(관우 = 특급, 강습 개방 명중 1)는 상시 효과로 그대로 둔다. 이 특기는 그 위에 성공률을 더한다",
     "text": "「만인지적」 — 60초 동안 강습 성공률 +30%p, 강습 재사용 대기 초기화. 강습모함이 있어야 쓴다."},
    {"id": "SK-U-ZHUGE", "trait": "신기묘산", "officer": "CHR-0134", "name": "신기묘산", "target": "self", "duration_s": 120,
     "effects": {"transition_mul_bp": 0, "affinity_ignore": True},
     "ai_when": {"all": [{"enemy_in_band": "barrage"}]},
     "relation": "formation_rules.master_trait(팔진 사용 자격)는 상시 효과로 그대로 둔다. 이 특기는 배치 재조정 1회를 진형 즉시 전환으로 옮긴 것이다",
     "text": "「신기묘산」 — 120초 동안 진형 전환이 즉시 끝나고(전환 중 피해 ×0.8 없음), 진형 상성 불리를 받지 않는다."},
    {"id": "SK-U-ZHAOYUN", "trait": "일신시담", "officer": "CHR-0136", "name": "일신시담", "target": "ally_fleet", "radius": 200, "duration_s": 30, "target_pick": {"from": "allied_fleets_in_radius", "include_self": True, "by": "lowest_hull_ratio", "tie": "id"},
     "effects": {"damage_taken_mul_bp": 0, "rescue_equipped": True},
     "requires": {"ally_within": 200},
     "ai_when": {"all": [{"ally_hull_below_bp_within": [4000, 200]}]},
     "relation": "commander_casualties 표의 '구조 장비 아군 함대 반경 안'을 효과 동안 이 함대에도 적용한다",
     "text": "「일신시담」 — 200 안의 아군 함대 하나(자기 포함): 30초 동안 받는 사격 피해 0, 지휘관 구조 판정에서 구조 함대로 본다."},
    {"id": "SK-U-HUANGZHONG", "trait": "강궁", "officer": "CHR-0138", "name": "강궁", "target": "self", "duration_s": 120,
     "effects": {"range_mul_bp": 13000, "categories": ["artillery"]},
     "ai_when": {"all": [{"enemy_beyond_base_range_within_mul": ["artillery", 13000]}]},
     "relation": "사거리 원(P2)은 효과 중 늘어난 포격 사거리를 그려야 한다",
     "text": "「강궁」 — 120초 동안 포격(미사일) 사거리 +30%."},
    {"id": "SK-U-ZHOUYU", "trait": "미주랑", "officer": "CHR-0211", "name": "미주랑", "target": "side", "duration_s": 180,
     "effects": {"chain_power_mul_bp": 13000},
     "ai_when": {"all": [{"wind_window_open": True}]},
     "relation": "chain_operation.power_by_range에 곱한다(최대 0.5 → 0.65). 화공 발동·번짐 규칙은 그대로",
     "text": "「미주랑」 — 180초 동안 연합 진영 화공 위력 +30%."},
    {"id": "SK-U-HUANGGAI", "trait": "고육계", "officer": "CHR-0217", "name": "고육계", "target": "self", "duration_s": 0,
     "effects": {"alias_command": "letter"},
     "requires": {"chain_host": True},
     "ai_when": {"all": [{"chain_host_ai": True}]},
     "relation": "새 효과가 없다. 기존 서신 명령(letter, feigned_surrender.letter_uses 1)을 슬롯에서 부르는 단축이다. 사용 여부도 letter_uses를 그대로 쓴다. AI는 기존 chain_host_ai를 따른다",
     "text": "「고육계」 — 위장 항복 서신을 보낸다(화공 운용 함대만)."},
    {"id": "SK-U-GUOJIA", "trait": "귀모", "officer": "CHR-0003", "name": "귀모", "target": "self", "duration_s": 120,
     "effects": {"reveal_radius": 600, "reveal_orders": True},
     "ai_when": {"all": [{"estimated_within": 600}]},
     "relation": "탐지 규칙(진영 공유 Q46)으로 확인된 접촉은 진영 전체가 본다",
     "text": "「귀모」 — 120초 동안 600 안의 적 함대를 확인 상태로 올리고 그 이동 목표를 보여 준다."},
    {"id": "SK-U-DIANWEI", "trait": "악래", "officer": "CHR-0030", "name": "악래", "target": "self", "radius": 200, "duration_s": 120,
     "effects": {"damage_redirect_bp": 5000},
     "requires": {"ally_flagship_within": 200, "self_not_flagship": True},
     "ai_when": {"all": [{"ally_flagship_within": 200}, {"ally_flagship_hull_below_bp": 8000}]},
     "relation": "기함 함대가 받는 선체 피해의 50%를 이 함대가 대신 받는다. 같은 함대가 기함이면 효과 없음",
     "text": "「악래」 — 120초 동안 200 안의 아군 기함 함대가 받는 사격 피해의 절반을 대신 받는다."},
    {"id": "SK-U-XUCHU", "trait": "호치", "officer": "CHR-0047", "name": "호치", "target": "allies_in_radius", "radius": 200, "include_self": True, "duration_s": 120,
     "effects": {"assault_block": True},
     "ai_when": {"all": [{"enemy_carrier_within": 200}]},
     "relation": "combat.assault.flagship.escort_trait(호치, 기함 강습 성공률 ×0.5)는 상시 효과로 그대로 둔다. 이 특기는 효과 동안 반경 안 아군 함대에 대한 강습을 막는다",
     "text": "「호치」 — 120초 동안 200 안의 아군 함대는 강습을 받지 않는다."},
    {"id": "SK-U-CAOREN", "trait": "철벽", "officer": "CHR-0033", "name": "철벽", "target": "self", "duration_s": 180,
     "effects": {"damage_taken_mul_bp": 6667, "only_while": "holding"},
     "ai_when": {"all": [{"enemy_in_band": "engagement"}]},
     "relation": "본편 '방어 시 전열함 내구 +50%'를 정지(이동 명령 없음) 중 받는 피해 ×1/1.5로 옮겼다",
     "text": "「철벽」 — 180초 동안 멈춰 있는 사이 받는 사격 피해 −33%."},
    {"id": "SK-U-XIAHOUYUAN", "trait": "신속", "officer": "CHR-0044", "name": "신속", "target": "self", "duration_s": 90,
     "effects": {"speed_mul_bp": 14000, "damage_taken_mul_bp": 11500},
     "ai_when": {"any": [{"self_retreating": True}, {"enemy_in_band": "barrage"}]},
     "relation": "본편 단점(매복 피해 +30%)을 효과 중 받는 피해 +15%로 옮겼다",
     "text": "「신속」 — 90초 동안 이동 속도 +40%. 그동안 받는 사격 피해 +15%."},
    {"id": "SK-U-HAOZHAO", "trait": "진창", "officer": "CHR-0046", "name": "진창", "target": "self", "duration_s": 180,
     "effects": {"damage_taken_mul_bp": 8000, "morale_loss_mul_bp": 7000,
                 "in_terrain": {"damage_taken_mul_bp": 6000, "morale_loss_mul_bp": 5000}},
     "ai_when": {"all": [{"enemy_in_band": "engagement"}]},
     "relation": "적벽에는 회랑이 없어 '회랑'을 지형 구역(성운·잔해대·행성 그림자) 안으로 옮겼다",
     "text": "「진창」 — 180초 동안 받는 사격 피해 −20%, 사기 감소 −30%. 지형 구역 안이면 −40%·−50%."},
]

# 나머지 특성 → 유형(Q88). 근거는 본편 characters.json 특성 설명의 낱말(SPECIAL-SKILLS.md §3). 여기에 없는 특성은 최고 능력치로 정한다.
TRAIT_TYPE = {
    # 화력: 무용·선봉·정예·토벌·포박
    "부풍": "firepower", "금마초": "firepower", "부자": "firepower", "강동지호": "firepower", "선봉": "firepower",
    "포박": "firepower", "산월토벌": "firepower", "무릉 평정": "firepower", "이릉 분전": "firepower",
    "여강 정예": "firepower", "대장군": "firepower", "황수아": "firepower",
    # 방어: 방어·농성·호위·노장·내구
    "무당비군": "defense", "노익장": "defense", "고수": "defense", "노장": "defense", "고절": "defense", "종자": "defense",
    "백모병": "defense", "만신창이": "defense", "변경": "defense", "수비": "defense", "낭고": "defense",
    # 기동: 이동·기습·돌파·추격·항행
    "소패왕": "maneuver", "백의도강": "maneuver", "주아부의 풍": "maneuver",
    "교변": "maneuver", "천리구": "maneuver", "호표기": "maneuver", "수군": "maneuver",
    # 사기: 결속·인덕·안정·군기·여걸·사기
    "인고": "morale", "궁요희": "morale", "목우유마": "morale", "변설": "morale", "백미": "morale", "남중 회유": "morale", "장판": "morale", "집행": "morale", "조정": "morale", "인덕": "morale",
    "사직지기": "morale", "순절": "morale", "천하이분": "morale", "강동이교": "morale", "군기": "morale", "국태": "morale",
    "순직": "morale", "화평": "morale", "원로": "morale", "낙신": "morale", "내조": "morale", "사군자": "morale",
    "호가십팔박": "morale", "독안": "morale", "진무": "morale", "병주 안무": "morale",
    "청주 진무": "morale", "조율": "morale",
    # 교란: 계략·이간·외교·회유·야습·위압
    "담병": "disrupt", "봉추": "disrupt", "기모": "disrupt", 
    "연인": "disrupt", "금범적": "disrupt", "밀서": "disrupt", "독사": "disrupt", "십이기책": "disrupt",
    "이간": "disrupt",
    # 탐지: 정보·내응·선견·정찰
    "내응": "detection", "선견": "detection", "의성": "detection",
    # 조달: 보급·재정·내정·둔전
    "거상": "supply", "탁고": "supply", "보급": "supply", "직백전": "supply", "교주": "supply",
    "중신": "supply", "청렴": "supply", "남방 경략": "supply", "교주 경략": "supply", "혹리": "supply", "왕좌지재": "supply",
    "가재": "supply", "관중경영": "supply", "구품관인법": "supply", "경제": "supply", "하동 경영": "supply", "염철": "supply",
    "둔전 운영": "supply", "둔전 창시": "supply", "둔전 호위": "supply",
}
# 낱말 근거가 없거나 약한 특성은 특성 단위로 수작업 배정한다(basis "assign", REVIEW-P8-0 F-6). 같은 특성은 같은 유형이다.
# 여걸(상위 기술) 장수는 모두 격려다. 외교·회유 계열(변설·백미·남중 회유)은 아군 쪽 효과라 격려다(Q94).
TRAIT_ASSIGN = {
    "반골": "firepower", "불안": "morale", "오만": "disrupt", "효심": "morale", "유재시거": "morale", "대관출전": "defense",
    "모주": "supply", "종실지신": "morale", "인단": "morale", "호이": "firepower", "강직": "defense", "선양": "morale",
    "은일": "supply", "봉천자": "detection", "명사": "morale", "장형": "supply", "하서": "defense", "지절": "defense",
    "경학": "detection", "칠보": "detection", "장자": "defense", "돈황": "supply", "종군": "supply", "청류": "supply",
    "양자": "firepower", "이반": "maneuver", "직언": "morale", "숙련": "defense", "원망": "disrupt", "방자": "firepower",
    "원한": "firepower", "역전": "firepower", "이장": "supply", "사위": "disrupt", "사령": "supply"}


def special_skills(pool):
    """realtime_rules.special_skills: 기술 정의 + 장수별 기술(by_officer). 가용 장수 특성 누락 0을 여기서 검사한다."""
    unique = {u["trait"]: u for u in SKILL_UNIQUE}
    assert not set(TRAIT_TYPE) & set(TRAIT_ASSIGN) and not (set(TRAIT_TYPE) | set(TRAIT_ASSIGN)) & set(unique)
    by_officer, used, used_assign = {}, set(), set()
    for fid in sorted(pool):
        for o in pool[fid]:
            if not o["traits"]:
                continue   # 특성 없는 장수는 기술 없음(Q88)
            t = o["traits"][0]   # 장수당 기술 1개(첫 특성)
            if t in unique:
                assert unique[t]["officer"] == o["id"], (t, o["id"])
                sid, basis = unique[t]["id"], "unique"
            elif t in TRAIT_TYPE:
                sid, basis = SKILL_TYPE_BY_TYPE[TRAIT_TYPE[t]], "keyword"
                used.add(t)
            else:
                sid, basis = SKILL_TYPE_BY_TYPE[TRAIT_ASSIGN[t]], "assign"   # 없으면 KeyError = 매핑 누락
                used_assign.add(t)
            if "여걸" in " ".join(CHAR[o["id"]].get("traits", [])):
                assert sid == SKILL_TYPE_BY_TYPE["morale"], (o["id"], t)   # 여걸 → 격려
            by_officer[o["id"]] = {"skill": sid, "trait": t, "basis": basis}
    assert used_assign == set(TRAIT_ASSIGN), set(TRAIT_ASSIGN) - used_assign
    seen = {}
    for v in by_officer.values():   # 같은 특성은 같은 기술
        assert seen.setdefault(v["trait"], v["skill"]) == v["skill"], v
    assert used == set(TRAIT_TYPE), set(TRAIT_TYPE) - used   # 표에 오타·죽은 항목 없음
    assert {u["officer"] for u in SKILL_UNIQUE} <= set(by_officer)
    skills = [dict(u, kind="unique", status="proposed") for u in SKILL_UNIQUE]
    skills += [dict(t, kind="type", status="proposed") for t in SKILL_TYPES]
    return {
        "uses_per_battle": 1, "slots": 3, "slot_default": ["admiral", "vice", "staff_assault"],
        "use_scope": "fleet_skill_pair", "no_duplicate_skill_in_fleet": True,
        "stacking": {"damage_taken_reduction": "min_only", "damage_taken_increase": "max_only", "speed_mul": "max_only", "transition_mul": "min_only", "other": "multiply",
                     "note": "Q95: 받는 피해 감소(<10000)는 가장 낮은 배율 하나만, 증가(>10000)는 가장 큰 하나만 따로 고르고 둘을 곱한다"},
        "ai_eval": "AI 결정 틱마다 함대 ID 순 → 슬롯 순으로 ai_when을 보고, 함대당 한 틱에 하나만 발동한다",
        "skills": skills, "by_officer": by_officer,
        "definitions": {"holding": "이동 명령·경유점이 없고 후퇴·돌격 접근 중이 아니다(진형 전환 중은 holding)", "damage_reduction_stack": "Q95: 받는 피해 감소는 가장 낮은 배율 하나만",
                         "assault_bp_order": "escort 배율 뒤에 더하고 [min_bp, max_bp]로 clamp한 다음 forced_div", "distance_band_order": "contact > barrage > engagement > assault (가까울수록 작다). enemy_in_band b = 그 거리대 이내"},
        "note": "Q88~Q95·D4. 장수당 기술 1개(첫 특성). 특성 없는 장수는 기술 없음. 효과 키·조건 문법은 docs/battle-core/SPECIAL-SKILLS.md",
        "status": "proposed", "source": "본편 combat.md §9, characters.json traits, BATTLE_DECISIONS §U"}


if __name__ == "__main__":
    scenario = {
        "schema_version": 1,
        "scenario_id": "RED-CLIFFS-208-RT",
        "title": "적벽대전 (실시간 전투 코어 시나리오)",
        "statement": "정사 기록과 본편 정본(combat.md §4.3.3·§5.7, region-power.md §3.4)을 근거로 한 실시간 코어용 편성이다. 함선 수와 위치는 게임 수치이며 역사적 사실이 아니다. 본편 데모 setup(RED-CLIFFS-208-DIRECT)과 같은 스키마에 난이도 프로필과 지휘관 구성(부지휘관, 참모)을 더했다.",
        "based_on": {"setup_id": "RED-CLIFFS-208-DIRECT", "balance_profile": "normal-demo-v1"},
        "battlefield_bounds": BOUNDS,
        "escape_points": {"cao_cao": {"position": [1600, 300], "arrival_radius": 60},
                          "liu_sun_alliance": {"position": [0, 650], "arrival_radius": 60}},
        "historical_scale": {
            "cao_cao": {"claimed": "수군 80만 (조조가 손권에게 보낸 글, 『강표전』)",
                        "estimate": "중원군 15~16만 + 형주 항복군 7~8만 (주유의 판단, 『강표전』)",
                        "canon_mobilization": 101, "canon_ships": 2367},
            "sun_quan": {"estimate": "3만 (주유·정보, 『강표전』)", "canon_mobilization": 31},
            "liu_bei": {"estimate": "관우 수군 1만 + 유기 강하군 1만 이상 (『삼국지』 제갈량전)", "canon_mobilization": 15},
            "ratio_note": "인원 기준 조조:연합은 약 4.4~4.8배, 본편 정본의 동원 국력 기준은 2.20배(101 대 46). 상급 난이도를 정본 2.20배에 맞춘다. 연합 안의 손권:유비는 인원 기준 3:2를 따른다(정본 동원 국력은 31:15)."},
        "difficulty_policy": {
            "scope": "시나리오 모드 전용. 캠페인 전투는 ai-design.md §9(자원 보너스 없음)를 따른다.",
            "cao_scale_rule": "조조군 함대는 squadrons 순서대로 앞에서부터 difficulty_profiles.*.cao_fleets개를 배치한다(Q82). 자동 편성(Q80·Q81)은 마지막 배치 함대만 지휘 한도 × cao_last_fill_bp까지 채운다. cao_cost_at_limits = 그때의 조조 비용 합(target_cost_ratio × 연합 한도 합).",
            "alliance_rule": "연합 편성은 모든 난이도에서 같다.",
            "morale_rule": "조조군 전대의 시작 사기는 morale_group(northern, jing_navy)별 값을 쓴다. 연합은 10000bp.",
            "ai_rule": "AI 수준은 ai-design.md §9 표의 사고 깊이·실수율·반응 지연을 따른다. 정보는 모든 난이도에서 같은 안개다. 극한의 완전 정보는 쓰지 않는다."},
        "difficulty_order": ORDER,
        "difficulty_profiles": DIFF,
        "factions": [
            {"id": "liu_bei", "name": "유비군", "control": "player", "supreme_commander": "유비", "not_deployed": []},
            {"id": "sun_quan", "name": "손권군", "control": "ai_delegate", "supreme_commander": "주유", "not_deployed": NOT_DEPLOYED["sun_quan"]},
            {"id": "cao_cao", "name": "조조군", "control": "ai", "supreme_commander": "조조", "not_deployed": NOT_DEPLOYED["cao_cao"]}],
        "squadrons": SQUADRONS,
        "realtime_rules": {
            "source": "EXPERIENCE-DESIGN.md §1~§4, §8 세트 RX (밸런스 2차, 2026-10-03)",
            "deploy_rule": "조조군 전대는 deploy_delay_s(초) 동안 배치 위치에서 대기한 뒤 출발한다. 선봉 0, 주력 180, 후군 360",
            "range_band_hold": {"barrage_hold_s_after_first_hit": 720, "barrage_distance": 240, "engagement_hold_s": 360, "engagement_distance": 170, "assault_distance": 100, "note": "양측 AI가 첫 명중 뒤 12분은 포화 거리, 다음 6분은 교전 거리를 유지한다"},
            "sun_support_ai": "손권군 전대는 아군 전대에서 300 안에 들어온 적에게 접근한다",
            "wind_window": {"start_after_first_hit_s": [540, 600], "duration_s": 180, "note": "시드로 시작 시각을 정하고 1막에 예보한다"},
            "chain_host_ai": "황개 화공대는 기류 창 전에는 모든 적에게서 280 밖에 대기하고, 창이 열리면 투항 상태로 가장 가까운 밀집 전대에 120까지 접근해 발동한다",
            "chain_morale_shock_scale": {"target_squadron": 0.5, "army": 0.25, "note": "화공 사기 충격(전대 3500, 군 2500)에 위력/0.4를 곱한 뒤 이 배율을 곱한다"},
            "fog_override": {"estimated_confidence_basis_points": 7500, "note": "본편 데이터 5000. 진영 공유 탐지(Q46)에서 규모가 작은 전대도 싸울 수 있게 올렸다(EXPERIENCE-DESIGN.md §8 탐지 재조정)"},
            "formation_classes": {"dense": ["FRM-02", "FRM-03", "FRM-04"], "dispersed": ["FRM-05", "FRM-06", "FRM-07"], "neutral": ["FRM-01"], "note": "본편 red-cliffs-chain-explosion-rules.json의 분류. 밀집은 연환 보너스(사기 감소 ×0.8), 분산 북방군은 역병(10초마다 −40bp), 중립(어린진)은 둘 다 없음"},
            # 아래는 제안서 v0.3 §4.6·§4.7·§4.11·§5.5와 EXPERIENCE-DESIGN.md §2~§5·§9의 실시간 전용 수치다.
            # 코어가 규칙 수치를 코드에 두지 않도록(M2 완료 기준) 여기에 모은다. status "proposed" = 제안값(M4·M9에서 측정)
            "linked_ships_and_plague": {"dense_cao_morale_loss_mul": 0.8, "plague_group": "northern", "plague_interval_s": 10, "plague_loss_bp": 40,
                                        "status": "proposed", "basis": "무제기의 대역(大疫). 묶어야 버티고 묶으면 탄다"},
            "morale_events": {
                "army_recovery_bp": {"enemy_squadron_retreat_or_surrender": 300, "flagship_boarding_success": 1000},
                "army_loss_bp": {"own_squadron_retreat_or_surrender": 500, "chain_fire_hit": 2500, "feigned_surrender_hit": 4000,
                                 "flagship_boarding_allowed": 4000, "duel_loss": 4000, "ambush_hit": 1500},
                "rally": [{"id": "liu_bei_rally", "squadron_id": "RC-LIU-SQ-01", "uses": 1, "charm": CHAR["CHR-0128"]["stats"]["매력"]},
                          {"id": "zhou_yu_rally", "squadron_id": "RC-SUN-SQ-01", "uses": 1, "charm": CHAR["CHR-0211"]["stats"]["매력"], "status": "proposed"}],
                "rally_effect": {"radius": 200, "morale_bp_at_charm_99": 1200, "scale": "charm / 99", "loss_mul": 0.5, "loss_mul_s": 30},
                "crisis_threshold_bp": 4500, "collapse_threshold_bp": 3000,
                "status": "proposed"},
            "chain_operation": {
                "charges": 2, "consume_per_use": True, "trigger_range": 240, "target_must_be": ["dense", "confirmed_contact"], "wind_cone_deg": 60,
                "power_by_range": [[240, 0.25], [120, 0.40], [60, 0.50]], "power_interp": "linear", "breakaway_heavy_damage_share": 0.25,
                "spread": {"radius": 150, "interval_s": 20, "max": 2, "power_mul_each": 0.5},
                "result_grades": ["흔들림", "큰 타격", "연환 대화재"],
                "feigned_surrender": {
                    "letter_uses": 1, "ceasefire_while_suspicion_below": 100,
                    "suspicion_per_s": "difficulty_profiles.*.ai.suspicion_per_s",
                    "modifiers": {"fast_approach_rate_mul": 1.5, "escort_per_squadron_per_s": 0.3, "escort_radius": 130,
                                  "alliance_hit_near_host": 10, "alliance_hit_radius": 300, "in_nebula_rate_mul": 0.5,
                                  "self_inflicted_hull_damage_min": 0.10, "self_inflicted_start_suspicion": -30, "cheng_yu_absent_rate_mul": 0.5},
                    "on_detected": {"target_to_dispersed": True, "focus_fire_on_host": True, "alliance_army_loss_bp": 1500},
                    "warnings": [50, 80]},
                "cao_counters": [
                    {"id": "emergency_disperse", "radius": 150, "duration_s": 30, "min_difficulty": "상급"},
                    {"id": "interception_net", "radius": 200, "min_interceptor_platforms": 8, "second_run_power_mul": 0.5, "min_difficulty": "표준"},
                    {"id": "cut_off", "cao_army_loss_bp": 1000, "min_difficulty": "표준"}],
                "counter_uses_per_fire": 1,
                "linked_formation_ai": {"spacing": [120, 180]},
                "target_success_ai_vs_ai": {"상급": 0.274},
                "status": "proposed"},
            # G8-04 (본편 V-74 잠정값, 제안서 §4.14, UPSTREAM-ISSUES §E). 포획 반경·혼선은 M9에서 측정한다
            "commander_succession": {
                "order": ["vice_commander", "staff_assault_siege_supply"], "note": "Q73·Q74: 편제 한 단계. 함대 제독이 지휘 불능이면 같은 함대의 부제독 → 참모(강습 → 공성 → 보급)가 잇고 그 함대가 60초 혼선. 이을 사람이 없으면 끝까지 혼선",
                "confusion": {"duration_s": 60, "penalty_stage_equivalent": 2, "max_stage": 4,
                              "effect_per_stage": {"move_pct": -5, "hit_pct": -4, "formation_change_pct": -8},
                              "no_candidate": "until_battle_end", "random_order_failure": False},
                "recompute_command_limit": True,
                "status": "proposed", "source": "제안서 §4.14, UPSTREAM-ISSUES §E (본편 V-74)"},
            "commander_casualties": {
                "capture_radius": 120, "rescue_radius": 120, "evaluated_at": "event_tick",
                "hull_ratio_basis": "surviving_ship_count_ratio",
                "table": [
                    {"order": 1, "when": "squadron_surrender_by_zero_morale", "result": "captured_all_aboard"},
                    {"order": 2, "when": "drifting_fast_craft_captured", "result": "captured"},
                    {"order": 3, "when": "hull_zero_sunk", "branches": [
                        {"order": 1, "when": "same_tick_chain_explosion_sinking", "result": "killed"},
                        {"order": 2, "when": "friendly_rescue_equipped_squadron_within_radius", "result": "severe_survive"},
                        {"order": 3, "when": "no_enemy_operational_squadron_within_radius", "result": "severe_survive"},
                        {"order": 4, "when": "nearest_friend_distance_le_nearest_enemy_distance", "result": "severe_survive", "tie": "friend"},
                        {"order": 5, "when": "otherwise", "result": "captured"}]},
                    {"order": 4, "when": "hull_ratio_below_0.4_above_0", "result": "severe", "scope": "squadron_commander_only", "effect": "command_incapacitated"},
                    {"order": 5, "when": "hull_ratio_0.4_to_0.75", "result": "light", "scope": "squadron_commander_only", "effect": "command_kept"},
                    {"order": 6, "when": "forced_retreat_outside_own_exit_at_battle_end_enemy_wins", "result": "captured"}],
                "operational_means": "not_retreating_surrendered_or_drifting",
                "states": ["unhurt", "light", "severe", "killed", "captured"], "terminal": ["killed", "captured"],
                "cao_cao": {"flagship_sunk_by_chain_fire": "killed", "flagship_sunk_enemy_close_only": "captured", "flagship_sunk_otherwise": "severe_escape_huarong", "flagship_surrender": "captured"},
                "instant_result": {"liu_bei_killed_or_captured": "alliance_defeat", "cao_cao_killed_or_captured": "alliance_victory", "simultaneous": "cao_first", "severe": "succession_only"},
                "status": "proposed", "source": "제안서 §4.14, UPSTREAM-ISSUES §E (본편 V-74)"},
            "decision_cards": {"time_game_s": 30, "speed_by_difficulty": {"입문": 0.0, "표준": 0.2, "상급": 1.0, "극한": 1.0},
                               "precursor_s": 3, "on_timeout": "recommended_option", "target_count": [4, 6],
                               "suspicion_80": {"form": "card", "time_game_s": "min(30, 간파까지 남은 게임 초 - 2)", "on_timeout": "recommended_option"},
                               "quick_alert": {"used_for": "suspicion_50", "time_real_s": 2, "speed": 0.2, "on_timeout": "continue"},
                               "source": "EXPERIENCE-DESIGN.md §5, NARRATIVE-RED-CLIFFS.md §1"},
            "seed_variation": {"wind_window_start": "wind_window.start_after_first_hit_s", "jing_navy_start_morale_bp_delta": [-500, 500],
                               "cao_wave_order": "주력·후군 안의 전대 순서", "public_seed": True, "status": "proposed", "source": "EXPERIENCE-DESIGN.md §9 R1"},
            "cao_dispositions": {"pick": "seed", "reveal": "결산",
                                 "options": [{"id": "cautious", "name": "신중", "behavior": "밀집을 빨리 푼다"},
                                             {"id": "aggressive", "name": "공세", "behavior": "조기 강습"},
                                             {"id": "deceptive", "name": "기만", "behavior": "형주 수군을 미끼로 쓴다"}],
                                 "status": "proposed", "source": "EXPERIENCE-DESIGN.md §9 R2"},
            "what_if_cards": [
                {"id": "southeast_wind", "name": "동남풍 「단 위의 사흘 밤」", "effect": "기류 창 시작을 배치 단계에서 한 번 고른다", "pick_range_after_first_hit_s": [360, 720], "duration_s": 180},
                {"id": "double_agent", "name": "반간계 「장간의 서신」", "effect": "형주 수군 을의 사기 −1000, 지휘관을 모개로 교체", "target_squadron_id": "RC-CAO-SQ-05", "morale_bp": -1000, "replacement_commander": "CHR-0058"},
                {"id": "cheng_yu_insight", "name": "정욱 간파 「가볍게 뜬 배」", "effect": "화공 표적 하나가 처음부터 분산 진형"}],
            "special_skills": special_skills(POOL),
        },
        "chain_explosion_override": {"host_squadron_id": "RC-SUN-SQ-03", "operator_faction_id": "liu_bei",
                                     "note": "본편 데이터는 주유 전대를 운용 전대로 두었다. 정사에서 화공을 이끈 것은 황개이므로 황개 화공대로 옮긴다."},
        "open_issues": [
            "기함: 본편 데모는 제갈량 전대를 유비군 기함으로 두었으나, 이 시나리오는 정사에 따라 유비 본대를 기함으로 두고 제갈량을 참모·함대 부지휘관으로 둔다. 승패 조건의 기함이 바뀐다.",
            "채모·장윤: 정사(생존)와 본편 combat.md §1.4 서술(연의, 처형)이 다르다. 이 시나리오는 정사를 따른다.",
            "통솔 값: 본편 demo_roster가 characters.json과 달랐다(제갈량 96/92, 주유 97/96, 노숙 85/82, 손권 81/76, 조인 90/89, 하후돈 89/88). 본편이 characters.json을 정본으로 확정하고 데모를 맞췄다(본편 V-73, 2026-10-04). 이 시나리오는 characters.json을 쓴다.",
            "난이도로 조조군 규모를 바꾸는 것은 ai-design.md §9(자원 보너스 없음)와 충돌한다. 시나리오 모드 전용 예외로 둔다(세션 Q44)."],
    }
    for f in scenario["factions"]:
        f["available_officers"] = POOL.get(f["id"], [])
    # 이 파일 기준 경로로 쓴다(worktree에서 돌려도 그 worktree의 파일을 고친다)
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "data", "scenarios", "red_cliffs_208_realtime.json")
    json.dump(scenario, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    ally = sum(s["declared_total_cost"] for s in SQUADRONS if s["faction_id"] != "cao_cao")
    print("alliance cost", ally, {f: sum(s["declared_total_cost"] for s in SQUADRONS if s["faction_id"] == f) for f in ("liu_bei", "sun_quan")})
    for s in SQUADRONS:
        over = s["declared_total_cost"] / s["command_limit"]
        print(f"{s['id']:14} {s['commander']['name']:4} cost {s['declared_total_cost']:4} limit {s['command_limit']:4} {'OVER' if over > 1 else ''} ships {sum(c['count'] for c in s['composition'])}")
    for d in ORDER:
        sqs = apply_difficulty(SQUADRONS, d)
        cao = sum(s["declared_total_cost"] for s in sqs if s["faction_id"] == "cao_cao")
        ships = sum(c["count"] for s in sqs for c in s["composition"])
        cao_ships = sum(c["count"] for s in sqs if s["faction_id"] == "cao_cao" for c in s["composition"])
        print(d, "cao cost", cao, "ratio %.2f" % (cao / ally), "cao squadrons", sum(1 for s in sqs if s["faction_id"] == "cao_cao"), "cao ships", cao_ships, "total ships", ships)
        p = DIFF[d]
        print("   Q82 at limits: ally", ALLY_LIMIT, "cao", p["cao_cost_at_limits"], "ratio %.3f" % (p["cao_cost_at_limits"] / ALLY_LIMIT), "fleets", p["cao_fleets"], "last fill bp", p["cao_last_fill_bp"])
