import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
INPUTS = [
    "data/scenarios/red_cliffs_208_realtime.json",
    "data/profiles/red_cliffs_rt.json",
]
TICK_HZ = 10

def extract():
    raw = [(ROOT / path).read_bytes() for path in INPUTS]
    scenario, profile = map(json.loads, raw)
    assert profile["scenario_path"] == f"res://{INPUTS[0]}"
    sides = {row["id"]: profile["side_by_control"][row["control"]]
             for row in scenario["factions"]}
    difficulties = {}
    for name in scenario["difficulty_order"]:
        config = scenario["difficulty_profiles"][name]
        cap = config["cao_fleets"]
        rosters = [[], []]
        cao_count = 0
        for squadron in scenario["squadrons"]:
            faction = squadron["faction_id"]
            morale = 10000
            if "morale_group" in squadron:
                cao_count += 1
                if cao_count > cap:
                    continue
                morale = config["start_morale_bp"][squadron["morale_group"]]
            delay = squadron.get("deploy_delay_s", 0)
            rosters[sides[faction]].append({
                "id": squadron["id"], "faction_id": faction, "wait_s": delay,
                "wait_ticks": delay * TICK_HZ, "start_morale_bp": morale,
            })
        ally, foe = rosters
        difficulties[name] = {
            "cao_cap": cap, "ai": config["ai"], "ally": ally, "foe": foe,
            "brief_foe_ids": [row["id"] for row in foe if row["wait_s"] == 0],
        }
    return {
        "sources": {path: hashlib.sha256(buf).hexdigest()
                    for path, buf in zip(INPUTS, raw)},
        "tick_hz": TICK_HZ, "difficulty": difficulties,
    }

if __name__ == "__main__":
    oracle = Path(__file__).resolve().parent.parent / "data-oracle-v2.json"
    expected = json.loads(oracle.read_bytes())
    actual = extract()
    assert actual == expected
    print(f"Verified {hashlib.sha256(oracle.read_bytes()).hexdigest()}")
