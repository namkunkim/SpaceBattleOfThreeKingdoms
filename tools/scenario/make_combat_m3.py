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
                              "note": "§4.3 ±20%. 시나리오 데이터에 통솔만 있어 모든 거리대에 통솔을 쓴다. 지력·무력은 데이터가 생기면 거리대별로 바꾼다"},
                "formation_damage_mul": {"FRM-06": 0.9, "status": "proposed", "note": "§4.3 장사진 ×0.9. 상성 ×1.2, 전환 ×0.8은 M5"},
                "terrain_mul": 1.0,
            },
            "loss": {
                "exposed_share_bp": 6000,
                "source": "§4.4 세션 Q5·Q6 (제안값): 맞은 방향의 노출 함종 60%, 나머지 40%",
                "exposure": {
                    "FRM-01": {"front": ["SHP-04"], "flank": ["SHP-07", "SHP-03", "SHP-08"], "rear": ["SHP-05", "SHP-01"]},
                },
                "exposure_note": "M3는 어린진 표 하나로 모든 진형을 처리한다. 진형별 표 전체는 M5(§4.4)",
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
                "note": "전대 속도 = 편성에서 가장 느린 함종의 턴당 속도 / 60 (px/초) × (100 + 진형 기동%) / 100 (§4.2)",
            },
            "charge": {
                "heat_share_bp": 4000,
                "min_morale_bp": 6000,
                "status": "proposed (Q28·Q42: 열 40% + 사기 안정 조건)",
            },
            "start": {
                "face_nearest_foe": True,
                "phase_stagger": True,
                "note": "초기 방향은 가장 가까운 적 전대를 향한다(§4.2). 주기 시작 틱은 전대 ID에서 유도해 엇갈린다(§4.3)",
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
