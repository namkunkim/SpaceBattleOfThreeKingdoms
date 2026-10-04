#!/usr/bin/env python3
"""M3 사격·피해 규칙 데이터(data/profiles/combat_m3.json) 생성기.

본편 스냅숏(data/scenarios/base/)의 값은 그대로 옮기고, 제안서 §4.3~§4.8의 실시간 전용 값은
"status": "proposed" 또는 "source"를 달아 구분한다. 코어는 이 JSON만 읽는다(코드에 규칙 수치 없음).
JSON을 직접 고치지 말고 이 스크립트를 고친 뒤 다시 돌린다.

    python tools/scenario/make_combat_m3.py
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
BASE = os.path.join(ROOT, "data", "scenarios", "base")
OUT = os.path.join(ROOT, "data", "profiles", "combat_m3.json")


def load(name):
    with open(os.path.join(BASE, name), encoding="utf-8") as f:
        return json.load(f)


def main():
    ships = load("ship-types.json")
    setup = load("red-cliffs-demo-setup.json")
    effects = load("red-cliffs-combat-effects-rules.json")
    res = load("red-cliffs-combat-resource-rules.json")
    alloc = load("red-cliffs-weapon-allocation-rules.json")
    frm_rules = load("red-cliffs-formation-rules.json")
    frm = {f["id"]: f for f in load("formations.json")}
    move = load("red-cliffs-movement-rules.json")
    sens = load("red-cliffs-sensor-ew-rules.json")
    fog = load("red-cliffs-fog-of-war-rules.json")
    terr = load("red-cliffs-terrain-rules.json")
    ai = load("red-cliffs-ai-rules.json")

    cost = {s["id"]: s["unit_cost"] for s in setup["ship_types"]}
    types = {}
    for s in ships:
        pc = s["phase_coefficients"]
        types[s["id"]] = {
            "cost": cost[s["id"]],
            "speed_per_turn": move["base_speed_by_ship_type"][s["id"]],
            # 결착(resolution)은 보급함이 null(사기 유지 효과)이라 0으로 둔다. M4에서 결착을 쓸 때 다시 본다.
            "phase": {k: (v if v is not None else 0.0) for k, v in pc.items()},
        }

    formations = {}
    for fid, r in frm_rules["formations"].items():
        formations[fid] = {
            "name": r["name"],
            # 퍼센트를 bp로 옮긴다(명중률 식이 bp: (사격 화력% − 방어%) × 100)
            "mobility_bp": r["mobility_percent"] * 100,
            "detection_bp": r["detection_percent"] * 100,
            "fire_bp": r["fire_percent"] * 100,
            "defense_bp": r["defense_percent"] * 100,
            "phase": frm[fid]["coefficients"],
            "required_command": frm[fid]["required_command"],
        }

    weapons = {}
    for cat, w in alloc["weapons"].items():
        weapons[cat] = {
            "base_accuracy_bp": effects["hit"]["base_accuracy_basis_points"][cat],
            "base_damage": effects["damage_points"][cat],
            "platforms": {k: dict(v) for k, v in w["platforms"].items()},
            "equipment": {k: dict(v) for k, v in w["fast_equipment"].items()},
            "ammo_per_platform": res["weapon_initial_per_platform"][cat]["ammo"],
            "special_per_platform": res["weapon_initial_per_platform"][cat]["special"],
            "shot": dict(res["shot_cost"][cat]),
        }

    out = {
        "schema_version": 1,
        "profile_id": "combat-m3",
        "note": "M3 사격·피해 규칙. 본편 스냅숏(data/scenarios/base/)을 옮긴 값과 제안서 §4.3~§4.8의 실시간 전용 값(proposed)을 합쳤다. tools/scenario/make_combat_m3.py가 만든다.",
        "combat": {
            "damage_mode": "sqrt",
            "damage_mode_note": "fixed | sqrt | linear. 제안서 K1(Q45): 기본 sqrt. M3에서 세 방식을 같은 조건으로 비교한다(docs/core/M3-NOTES.md).",
            "categories": ["artillery", "line_fire", "intercept", "torpedo"],
            "period_s": 60,
            "period_source": "제안서 §4.3 Q46. 10~15초 대안은 M3 측정에서 비교(P12)",
            "weapons": weapons,
            "carrier": {
                "platform_key": "line_fire@SHP-01",
                "ship_type_id": "SHP-01",
                "category": "line_fire",
                "sorties_per_ship": res["platform_overrides"]["line_fire@SHP-01"]["carrier_sorties_per_platform"],
                "sorties_per_shot": res["carrier_platform_shot_cost"]["line_fire@SHP-01"],
                "range_loss_ship": "SHP-04",
                "range_without_carrier_note": "강습모함 0척이면 전열 사격 사거리가 190에서 180으로 준다(제안서 §4.4). 플랫폼 표가 함종별 사거리라 자동으로 맞는다.",
            },
            "ship_types": types,
            "fast_craft": {
                "ship_type_id": "SHP-08",
                "equipment_category": {"FAST-EQ-INTERCEPT": "intercept", "FAST-EQ-TORPEDO": "torpedo"},
                "hull_excludes_equipment": True,
            },
            "formations": formations,
            "default_formation": "FRM-01",
            "sector": {
                "front_deg": frm_rules["sector_rule"]["front_limit_deg"],
                "rear_deg": frm_rules["sector_rule"]["rear_limit_deg"],
                "defense_bp": {k: v * 100 for k, v in frm_rules["sector_defense_percent"].items()},
                "source": "본편 formation-rules, 세션 Q33. 경계는 정면 ≤60°, 후면 ≥120°(POC는 <60°였다)",
            },
            "hit": {
                "min_bp": effects["hit"]["minimum_basis_points"],
                "max_bp": effects["hit"]["maximum_basis_points"],
                "out_of_command_bp": 1000,
                "out_of_command_status": "proposed (§4.3: 지휘 범위 밖 명중률 −10%p)",
            },
            "hull": {
                "points_per_cost": effects["hull_points_per_ship_unit_cost_point"],
                "bands_bp": effects["hull_bands_basis_points"],
            },
            "damage": {
                "morale_base": 0.6,
                "morale_div_bp": 25000,
                "morale_note": "사기 계수 = 0.6 + 사기bp / 25000 (§4.3, 정본 식의 bp 환산)",
                "commander": {"pivot": 70, "spread": 30, "span": 0.2, "status": "proposed",
                              "stat_by_band": {"contact": ["intellect"], "barrage": ["intellect"], "engagement": ["command"],
                                               "assault": ["might"], "resolution": ["command", "might"]},
                              "note": "§4.3 ±20%. 거리대별 능력치: 접적·포화 지력, 교전 통솔, 강습 무력, 결착 통솔·무력(평균). 능력치가 데이터에 없는 전대는 통솔로 대신한다(M4, REVIEW-M3 후속)"},
                "formation_damage_mul": {"FRM-06": 0.9, "status": "proposed", "note": "§4.3 장사진 ×0.9. 상성 ×1.2와 전환 중 ×0.8은 combat.formation_rules"},
                "terrain_mul": 1.0,
            },
            "loss": {
                "exposed_share_bp": 6000,
                "source": "§4.4 세션 Q5·Q6 (제안값): 맞은 방향의 노출 함종 60%, 나머지 40%",
                "exposure": {
                    "FRM-01": {"front": ["SHP-04"], "flank": ["SHP-07", "SHP-03", "SHP-08"], "rear": ["SHP-05", "SHP-01"]},
                    "FRM-02": {"front": ["SHP-04", "SHP-07"], "flank": ["SHP-04", "SHP-08"], "rear": ["SHP-03", "SHP-05"]},
                    "FRM-03": {"front": ["SHP-04"], "flank": ["SHP-04"], "rear": ["SHP-04", "SHP-07"]},
                    "FRM-04": {"front": ["SHP-03", "SHP-04"], "flank": ["SHP-03", "SHP-08"], "rear": ["SHP-05", "SHP-02"]},
                    "FRM-05": {"front": ["SHP-01", "SHP-04"], "flank": ["SHP-07", "SHP-08"], "rear": ["SHP-05", "SHP-03"]},
                    "FRM-06": {"front": ["SHP-04"], "flank": ["SHP-03", "SHP-05", "SHP-01"], "rear": ["SHP-05"]},
                    "FRM-07": {"front": ["SHP-04"], "flank": ["SHP-04", "SHP-07"], "rear": ["SHP-04"]},
                },
                "exposure_note": "§4.4 진형별 노출 함종 표 전체(제안값, M5). 전환 중에는 이전 진형의 표를 쓴다",
            },
            "stage": {
                "names": ["intact", "light", "moderate", "heavy", "sunk"],
                "power": [1.0, 0.9, 0.65, 0.0, 0.0],
                "heavy_share_bp": {"contact": 8000, "barrage": 5000, "engagement": 6000, "assault": 7500, "resolution": 5500},
                "heavy_share_source": "정본 ship-specs.md §3.7 (§4.5)",
                "hull_floor": [
                    {"below_bp": 7500, "moderate_share_bp": 2500},
                    {"below_bp": 4000, "moderate_share_bp": 5000},
                ],
            },
            "resources": {
                "energy_base": res["shared_base"]["energy_capacity"],
                "energy_per_ship": res["shared_initial_per_ship"]["energy"],
                "heat_base": res["shared_base"]["heat_capacity"],
                "heat_per_ship": res["shared_initial_per_ship"]["heat_capacity"],
                "recovery_period_s": 60,
                "energy_recover_bp": res["resolution_start_recovery"]["energy_percent_of_capacity"] * 100,
                "carrier_recover_bp": res["resolution_start_recovery"]["carrier_percent_of_capacity"] * 100,
                "heat_cool_base": res["resolution_start_recovery"]["heat_dissipation"],
                "heat_cool_per_ship": 2,
                "heat_cool_status": "proposed (K5, Q49: 30 + 척 수 × 2)",
                "suppression_reasons": res["suppression_reasons"],
            },
            "bands": {
                "assault_r": 80,
                "assault_status": "proposed (§4.2)",
                "artillery_default_r": 260,
                "line_fire_default_r": 180,
                "note": "교전 거리대 = 전열 사격 사거리 안, 포화 = 포격 사거리 안(§4.2). 함종이 없으면 기본 사거리를 쓴다",
            },
            "movement": {
                "turn_div": 60,
                "turn_deg_per_s": 9,
                "strafe_speed_bp": 6000,
                "face_tolerance_deg": 1,
                "max_waypoints": move["max_waypoints"],
                "status": "proposed (turn_deg_per_s·strafe_speed_bp: §4.2 제자리 선회 180°에 20초, 평행 이동은 전진 속도의 60%. 정본에 수치 없음)",
                "note": "전대 속도 = 편성에서 가장 느린 함종의 턴당 속도 / 60 (px/초) × (100 + 진형 기동%) / 100 (§4.2). 경유점은 최대 max_waypoints(경유 + 목적지)",
            },
            "formation_rules": {
                "transition_s": 30,
                "untrained_transition_s": 60,
                "transition_damage_mul": 0.8,
                "defense_id": "FRM-03",
                "defense_note": "POC 방어진형 버튼은 삭제했다(§9 POC 처분). 같은 역할은 방원진이 맡고, 적 AI가 선체가 줄면 이 진형으로 바꾼다",
                "master_id": "FRM-07",
                "master_min_command": 90,
                "master_trait": "신기묘산",
                "master_transition_div": 2,
                "status": "Q24 전환 30초·통솔 미달 60초·전환 중 ×0.8. 팔진 전환 절반은 proposed(§4.7)",
                # 상성(정본 ship-specs §5.4): 키 진형이 값 진형에 우위. 교전 거리대만 ×affinity_mul. 팔진은 무효, 장사진은 formation_damage_mul
                "affinity": {"FRM-02": "FRM-01", "FRM-01": "FRM-03", "FRM-03": "FRM-05", "FRM-05": "FRM-04", "FRM-04": "FRM-02"},
                "affinity_mul": 1.2,
                "affinity_band": "engagement",
                "terrain": {
                    "base_route": {"name": "기저 항로", "banned": ["FRM-02", "FRM-04"]},
                    "mid_corridor": {"name": "중회랑", "only": ["FRM-03", "FRM-05", "FRM-06"]},
                    "great_corridor": {"name": "대회랑", "forced": "FRM-06"},
                    "source": "정본 ship-specs §5.3. 적벽 전장은 개활이라 시나리오 battlefield_class가 없으면 제한 없음",
                },
            },
            "charge": {
                "heat_share_bp": 4000,
                "min_morale_bp": 6000,
                "status": "proposed (Q28·Q42: 열 40% + 사기 안정 조건)",
            },
            "first_volley_stagger_s": {
                "value": 0,
                "status": "proposed",
                "note": "M3 리뷰 후보(§4.3): 전대가 첫 일제를 쏜 뒤 다음 주기에 0~N초를 더해 엇갈린다. 0이면 끈다. M4에서 0과 15를 같은 시드로 잰다",
            },
            "morale": {
                "state_bp": {"stable_min": 6000, "retreat_below": 3000},
                "hit": {
                    "min_bp": 300,
                    "hull_div": 5,
                    "band_weight_bp": {"contact": 8000, "barrage": 12000, "engagement": 20000, "assault": 16000, "resolution": 10000},
                    "sector_weight_bp": {"front": 10000, "flank": 12500, "rear": 15000},
                    "source": "제안서 §4.6 감소(세션 Q43), 거리대 가중은 §4.2(본편 combat.md §1.3)",
                },
                "ship_departure_bp": 200,
                "chain_hit_bp": 3500,
                "supply_relief": {"ship_type_id": "SHP-05", "min_share_bp": 1000, "band": "resolution", "loss_mul_bp": 6000, "source": "§4.6 보급함 10% 이상이면 결착 감소 ×0.6"},
                "rally_charm_max": 99,
                "status": "proposed (회복 외 수치는 본편 정본, 가중은 세션 Q43)",
            },
            "victory": {
                "check_period_s": 1,
                "time_limit_s": 1200,
                "loss_bp": 7000,
                "exit_key_by_side": ["liu_sun_alliance", "cao_cao"],
                "tie_winner_side": 1,
                "cost_policy": {"surrender": "lost", "escaped": "kept", "note": "항복한 전대의 잔존 척은 코스트 손실, 탈출한 전대는 잔존으로 센다(제안값)"},
                "commander": {"rescue_equipment": "FAST-EQ-RESCUE"},
                "source": "§4.12, 본편 red-cliffs-victory-rules.json (loss 7000bp, 20분 시계, 동시 성립·동률은 조조군)",
            },
            "start": {
                "face_nearest_foe": True,
                "phase_stagger": True,
                "note": "초기 방향은 가장 가까운 적 전대를 향한다(§4.2). 주기 시작 틱은 전대 ID에서 유도해 엇갈린다(§4.3)",
            },
            # M6 탐지와 전쟁 안개(§4.9). 점수 식과 임계는 본편 sensor-ew, 기억·신뢰도 감쇠는 fog-of-war(턴 → 60초 환산)
            "detection": {
                "ship_sensor": sens["ship_sensor_points"],
                "ship_ew": sens["ship_ew_points"],
                "equip_sensor": sens["fast_equipment_sensor_points"],
                "equip_ew": sens["fast_equipment_ew_points"],
                "intellect_bands": sens["intelligence_bands"],
                "distance_units_per_point": sens["distance_penalty"]["units_per_point"],
                "confirmed": 30,
                "confirmed_status": "proposed (본편 37. M6 측정: 37이면 표준 조조가 확인 등급을 거의 못 받는다 — attack 32%, none 0%. 30이면 100%. EXPERIENCE-DESIGN §8 3안)",
                "estimated": sens["thresholds"]["estimated"],
                "turn_s": 60,
                "memory_s": fog["contact_lifecycle"]["estimated_memory_turns"] * 60,
                "lost_s": 60,
                "confidence_bp": fog["contact_lifecycle"]["estimated_confidence_basis_points"],
                "confidence_loss_bp_per_turn": fog["contact_lifecycle"]["stale_confidence_loss_per_turn"],
                "confidence_min_bp": fog["contact_lifecycle"]["minimum_confidence_basis_points"],
                "error_radius": fog["contact_lifecycle"]["base_error_radius"],
                "error_radius_per_turn": fog["contact_lifecycle"]["error_radius_per_stale_turn"],
                "eval_period_s": 1,
                "strength_bands": 4,
                "sensor_bp_clamp": [-6000, 3000],
                "no_contact_patrol": {"offset": ai["postures"]["cao_cao"]["patrol_offset"], "source": "본편 red-cliffs-ai-rules.json cao_cao.no_contact_action=patrol. 접촉이 없고 투입 대기가 끝난 조조군 전대는 이 방향으로 전진한다"},
                "eval_status": "proposed (평가 주기 1초는 실시간 환산. 본편은 턴마다 한 번. strength_bands: 확인 접촉에 공개하는 전력 구간 수)",
                "source": "본편 red-cliffs-sensor-ew-rules.json, red-cliffs-fog-of-war-rules.json. 신뢰도 시작값은 시나리오 realtime_rules.fog_override가 덮는다",
            },
            "terrain": {
                "zones": [
                    {"id": z["id"], "type": z["type"], "name": z["name"], "rect": [z["shape"]["x"], z["shape"]["y"], z["shape"]["width"], z["shape"]["height"]],
                     "move_cost_bp": z["effects"]["movement_cost_basis_points"], "sensor_bp": z["effects"]["observer_sensor_percent"] * 100,
                     "conceal": z["effects"]["target_concealment_points"], "range_bp": z["effects"]["weapon_range_basis_points"],
                     "arc_deg": z["effects"]["weapon_arc_delta_deg"]}
                    for z in terr["zones"]
                ],
                "source": "본편 red-cliffs-terrain-rules.json. 겹침: 이동 비용 최댓값, 센서 합(−60~+30), 은폐 합, 사거리는 구역 ID 순 곱, 사격각 합",
            },
        },
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print("wrote", OUT)


if __name__ == "__main__":
    main()
