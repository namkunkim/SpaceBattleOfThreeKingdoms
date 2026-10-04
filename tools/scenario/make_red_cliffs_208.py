"""적벽 시나리오 데이터 생성기. data/scenarios/red_cliffs_208_realtime.json을 만든다.

본편 characters.json(통솔)과 red-cliffs-demo-setup.json(함종 비용)을 읽어 비용과 지휘 한도를 계산한다.
실행: python make_red_cliffs_208.py
"""
import json, math, os

CHAR = {c["id"]: c for c in json.load(open(r"C:\WorkSpace\Seonghanji\data\characters.json", encoding="utf-8"))}
SETUP = json.load(open(r"C:\WorkSpace\Seonghanji\data\red-cliffs-demo-setup.json", encoding="utf-8"))
COST = {s["id"]: s["unit_cost"] for s in SETUP["ship_types"]}
EQ = {e["id"]: e["unit_cost"] for e in SETUP["ship_types"][7]["mission_equipment"]}


def C(t, n, eq=None):
    d = {"ship_type_id": t, "count": n}
    if eq:
        d["mission_equipment_id"] = eq
    return d


def P(cid):
    c = CHAR[cid]
    st = c["stats"]
    return {"id": cid, "name": c["name"], "command": st["통솔"], "might": st["무력"], "intellect": st["지력"], "charm": st["매력"]}


def sq(id, fac, name, cmd, vice, staff, flag, pos, frm, comp, basis, **kw):
    d = {"id": id, "faction_id": fac, "name": name, "commander": P(cmd),
         "vice_commander": P(vice) if vice else None, "staff": [P(s) for s in staff],
         "flagship": flag, "initial_position": pos, "formation_id": frm, "composition": comp}
    d.update(kw)
    d["historical_basis"] = basis
    return d


SQUADRONS = [
    sq("RC-LIU-SQ-01", "liu_bei", "유비 본대", "CHR-0128", "CHR-0130", ["CHR-0134"], True, [310, 620], "FRM-03",
       [C("SHP-04", 4), C("SHP-05", 1), C("SHP-07", 2)],
       "유비는 번구(樊口)에서 주유와 합류했다. 장비·제갈량의 전투 중 역할은 기록이 없어 본대 소속으로 둔다."),
    sq("RC-LIU-SQ-02", "liu_bei", "관우 수군", "CHR-0107", None, [], False, [430, 600], "FRM-01",
       [C("SHP-03", 2), C("SHP-04", 3), C("SHP-07", 2)],
       "『삼국지』 제갈량전: 관우의 수군 정예 1만."),
    sq("RC-LIU-SQ-03", "liu_bei", "유기 강하군", "CHR-0325", None, [], False, [230, 700], "FRM-03",
       [C("SHP-03", 1), C("SHP-04", 3), C("SHP-05", 1)],
       "『삼국지』 제갈량전: 유기가 모은 강하의 병사 1만 이상. 유기는 하구(夏口)를 지켰다."),
    sq("RC-LIU-FC-01", "liu_bei", "조운 정찰 고속정대", "CHR-0136", None, [], False, [260, 770], "FRM-06",
       [C("SHP-08", 6, "FAST-EQ-RECON")],
       "본편 데모 편성을 유지한다. 조운의 적벽 전투 기록은 없다.",
       operational=True, deployment={"kind": "independent"}),
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
       morale_group="northern", deploy_min_difficulty="입문", deploy_delay_s=180),
    sq("RC-CAO-SQ-02", "cao_cao", "조인 선봉", "CHR-0033", None, [], False, [1330, 420], "FRM-01",
       [C("SHP-01", 1), C("SHP-03", 4), C("SHP-04", 10), C("SHP-07", 3)],
       "조인은 형주 평정에 종군하고 전투 뒤 강릉을 지켰다(조인전).",
       morale_group="northern", deploy_min_difficulty="입문", deploy_delay_s=0),
    sq("RC-CAO-SQ-03", "cao_cao", "서황 전대", "CHR-0017", "CHR-0009", [], False, [1530, 470], "FRM-03",
       [C("SHP-02", 2), C("SHP-03", 5), C("SHP-04", 9), C("SHP-05", 1)],
       "서황은 형주 정벌에 종군하고 뒤에 조인과 함께 강릉에서 주유를 막았다(서황전). 만총도 형주 정벌에 종군했다(만총전).",
       morale_group="northern", deploy_min_difficulty="입문", deploy_delay_s=180),
    sq("RC-CAO-SQ-04", "cao_cao", "형주 수군 갑", "CHR-0010", None, [], False, [1250, 150], "FRM-04",
       [C("SHP-03", 4), C("SHP-04", 8), C("SHP-05", 1), C("SHP-07", 2)],
       "문빙은 유종과 함께 항복해 중용되었다(문빙전). 주유는 형주 항복군 7~8만이 '아직 의심을 품고 있다'고 보았다(『강표전』).",
       morale_group="jing_navy", deploy_min_difficulty="입문", deploy_delay_s=0),
    sq("RC-CAO-SQ-05", "cao_cao", "형주 수군 을", "CHR-0330", "CHR-0329", [], False, [1330, 190], "FRM-03",
       [C("SHP-03", 3), C("SHP-04", 6), C("SHP-05", 1)],
       "채모는 유종의 항복을 이끌었고 정사에서는 처형되지 않았다. 채모·장윤의 처형은 『삼국지연의』의 장간 이야기다.",
       morale_group="jing_navy", deploy_min_difficulty="표준", deploy_delay_s=180),
    sq("RC-CAO-SQ-06", "cao_cao", "조순 호표 고속대", "CHR-0084", None, [], False, [1400, 560], "FRM-05",
       [C("SHP-07", 6), C("SHP-08", 10, "FAST-EQ-INTERCEPT")],
       "조순은 호표기를 이끌고 장판에서 유비를 추격했다(조순전). 그 정예 기동 부대를 고속 요격 전대로 옮긴다.",
       morale_group="northern", deploy_min_difficulty="상급", deploy_delay_s=360),
    sq("RC-CAO-SQ-07", "cao_cao", "조홍 후군", "CHR-0036", None, [], False, [1580, 250], "FRM-03",
       [C("SHP-03", 3), C("SHP-04", 6), C("SHP-07", 2)],
       "조홍의 적벽 종군은 기록이 분명하지 않다. 상급 이상에서만 배치하는 후군이다.",
       morale_group="northern", deploy_min_difficulty="상급", deploy_delay_s=360),
]


def cost(comp):
    return sum(c["count"] * (COST[c["ship_type_id"]] + EQ.get(c.get("mission_equipment_id", ""), 0)) for c in comp)


for s in SQUADRONS:
    s["declared_total_cost"] = cost(s["composition"])
    lim = 40 + 2 * s["commander"]["command"]
    s["command_limit"] = lim

DIFF = {
    "입문": {"count_factor": 0.70, "target_cost_ratio": 1.09,
           "start_morale_bp": {"northern": 8000, "jing_navy": 6000},
           "ai": {"think_depth": 1, "mistake_bp": 2500, "reaction_s": 120, "chain_risk_response": False, "chain_detect_mean_s": None, "suspicion_per_s": 0.4},
           "note": "역병과 원정 피로가 크고 형주 수군이 훈련되지 않았다. 조조는 밀집(연환)을 풀지 않는다."},
    "표준": {"count_factor": 0.70, "target_cost_ratio": 1.24,
           "start_morale_bp": {"northern": 8000, "jing_navy": 6500},
           "ai": {"think_depth": 2, "mistake_bp": 1000, "reaction_s": 60, "chain_risk_response": True, "chain_detect_mean_s": 60, "suspicion_per_s": 0.8},
           "note": "본편 데모의 보통 난이도에 해당한다."},
    "상급": {"count_factor": 1.00, "target_cost_ratio": 2.14,
           "start_morale_bp": {"northern": 9500, "jing_navy": 7500},
           "ai": {"think_depth": 3, "mistake_bp": 300, "reaction_s": 0, "chain_risk_response": True, "chain_detect_mean_s": 20, "suspicion_per_s": 1.5},
           "note": "본편 정본의 동원비 2.20배."},
    "극한": {"count_factor": 1.00, "target_cost_ratio": 2.14,
           "start_morale_bp": {"northern": 10000, "jing_navy": 9000},
           "ai": {"think_depth": 3, "mistake_bp": 0, "reaction_s": 0, "chain_risk_response": True, "chain_detect_mean_s": 10, "suspicion_per_s": 2.0},
           "note": "역병 없음, 형주 수군 정상 훈련. 규모는 상급과 같고 정보 이점은 없다."},
}
ORDER = ["입문", "표준", "상급", "극한"]


def apply_difficulty(squadrons, diff):
    """조조군 전대에 난이도를 적용한 편성을 돌려준다 (difficulty_policy.cao_scale_rule)."""
    p = DIFF[diff]
    out = []
    for s in squadrons:
        if s["faction_id"] != "cao_cao":
            out.append(dict(s, start_morale_bp=10000))
            continue
        if ORDER.index(diff) < ORDER.index(s["deploy_min_difficulty"]):
            continue
        comp = []
        for c in s["composition"]:
            n = int(math.floor(c["count"] * p["count_factor"] + 0.5))
            if c["count"] >= 1:
                n = max(1, n)
            comp.append(dict(c, count=n))
        out.append(dict(s, composition=comp, declared_total_cost=cost(comp),
                        start_morale_bp=p["start_morale_bp"][s["morale_group"]]))
    return out


if __name__ == "__main__":
    scenario = {
        "schema_version": 1,
        "scenario_id": "RED-CLIFFS-208-RT",
        "title": "적벽대전 (실시간 전투 코어 시나리오)",
        "statement": "정사 기록과 본편 정본(combat.md §4.3.3·§5.7, region-power.md §3.4)을 근거로 한 실시간 코어용 편성이다. 함선 수와 위치는 게임 수치이며 역사적 사실이 아니다. 본편 데모 setup(RED-CLIFFS-208-DIRECT)과 같은 스키마에 난이도 프로필과 지휘관 구성(부지휘관, 참모)을 더했다.",
        "based_on": {"setup_id": "RED-CLIFFS-208-DIRECT", "balance_profile": "normal-demo-v1"},
        "battlefield_bounds": [0, 0, 1600, 900],
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
            "cao_scale_rule": "조조군 전대마다 함종별 척 수 × count_factor를 half-up 반올림하고, 원래 1척 이상이면 최소 1척. 난이도가 deploy_min_difficulty보다 낮으면 그 전대를 배치하지 않는다.",
            "alliance_rule": "연합 편성은 모든 난이도에서 같다.",
            "morale_rule": "조조군 전대의 시작 사기는 morale_group(northern, jing_navy)별 값을 쓴다. 연합은 10000bp.",
            "ai_rule": "AI 수준은 ai-design.md §9 표의 사고 깊이·실수율·반응 지연을 따른다. 정보는 모든 난이도에서 같은 안개다. 극한의 완전 정보는 쓰지 않는다."},
        "difficulty_order": ORDER,
        "difficulty_profiles": DIFF,
        "factions": [
            {"id": "liu_bei", "name": "유비군", "control": "player", "supreme_commander": "유비", "not_deployed": []},
            {"id": "sun_quan", "name": "손권군", "control": "ai_delegate", "supreme_commander": "주유",
             "not_deployed": [{"id": "CHR-0194", "name": "손권", "reason": "시상(柴桑)에 머물렀다"},
                              {"id": "CHR-0214", "name": "태사자", "reason": "건창에서 유반을 막았다"}]},
            {"id": "cao_cao", "name": "조조군", "control": "ai", "supreme_commander": "조조",
             "not_deployed": [{"id": "CHR-0021", "name": "악진", "reason": "양양에 주둔"},
                              {"id": "CHR-0026", "name": "장료", "reason": "장사(長社)에 주둔"},
                              {"id": "CHR-0023", "name": "우금", "reason": "208년 적벽 종군 기록이 없다"}]}],
        "fleet_groups": [
            {"id": "RC-LIU-FLT-01", "faction_id": "liu_bei", "name": "유비 연합 전단", "admiral": "CHR-0128", "vice_admiral": "CHR-0134",
             "squadron_ids": ["RC-LIU-SQ-01", "RC-LIU-SQ-02", "RC-LIU-FC-01"], "flagship_squadron_id": "RC-LIU-SQ-01"},
            {"id": "RC-LIU-FLT-02", "faction_id": "liu_bei", "name": "강하군", "admiral": "CHR-0325", "vice_admiral": None,
             "squadron_ids": ["RC-LIU-SQ-03"], "flagship_squadron_id": "RC-LIU-SQ-03"},
            {"id": "RC-SUN-FLT-01", "faction_id": "sun_quan", "name": "주유 수군", "admiral": "CHR-0211", "vice_admiral": "CHR-0207",
             "squadron_ids": ["RC-SUN-SQ-01", "RC-SUN-SQ-02", "RC-SUN-SQ-03"], "flagship_squadron_id": "RC-SUN-SQ-01"},
            {"id": "RC-CAO-FLT-01", "faction_id": "cao_cao", "name": "조조 중군", "admiral": "CHR-0034", "vice_admiral": "CHR-0033",
             "squadron_ids": ["RC-CAO-SQ-01", "RC-CAO-SQ-02", "RC-CAO-SQ-03", "RC-CAO-SQ-06", "RC-CAO-SQ-07"], "flagship_squadron_id": "RC-CAO-SQ-01"},
            {"id": "RC-CAO-FLT-02", "faction_id": "cao_cao", "name": "형주 항복 수군", "admiral": "CHR-0010", "vice_admiral": "CHR-0330",
             "squadron_ids": ["RC-CAO-SQ-04", "RC-CAO-SQ-05"], "flagship_squadron_id": "RC-CAO-SQ-04"}],
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
                    "modifiers": {"fast_approach_rate_mul": 1.5, "escort_per_squadron_per_s": 0.3, "escort_radius": 100,
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
                "order": ["vice_admiral", "fleet_squadron_commander_by_level_then_command_then_id"],
                "confusion": {"duration_s": 60, "penalty_stage_equivalent": 2, "max_stage": 4,
                              "effect_per_stage": {"move_pct": -5, "hit_pct": -4, "formation_change_pct": -8},
                              "no_candidate": "until_battle_end", "random_order_failure": False},
                "recompute_command_limit": True, "vice_admiral_shares_flagship_fate": True, "vice_admiral_hull_injury": False,
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
        },
        "chain_explosion_override": {"host_squadron_id": "RC-SUN-SQ-03", "operator_faction_id": "liu_bei",
                                     "note": "본편 데이터는 주유 전대를 운용 전대로 두었다. 정사에서 화공을 이끈 것은 황개이므로 황개 화공대로 옮긴다."},
        "open_issues": [
            "기함: 본편 데모는 제갈량 전대를 유비군 기함으로 두었으나, 이 시나리오는 정사에 따라 유비 본대를 기함으로 두고 제갈량을 참모·함대 부지휘관으로 둔다. 승패 조건의 기함이 바뀐다.",
            "채모·장윤: 정사(생존)와 본편 combat.md §1.4 서술(연의, 처형)이 다르다. 이 시나리오는 정사를 따른다.",
            "통솔 값: 본편 demo_roster가 characters.json과 달랐다(제갈량 96/92, 주유 97/96, 노숙 85/82, 손권 81/76, 조인 90/89, 하후돈 89/88). 본편이 characters.json을 정본으로 확정하고 데모를 맞췄다(본편 V-73, 2026-10-04). 이 시나리오는 characters.json을 쓴다.",
            "난이도로 조조군 규모를 바꾸는 것은 ai-design.md §9(자원 보너스 없음)와 충돌한다. 시나리오 모드 전용 예외로 둔다(세션 Q44)."],
    }
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
