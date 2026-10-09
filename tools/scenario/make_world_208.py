"""본편 천하 지도(data/maps/galaxy-map.json, 지도 v3)에서 적벽 연동에 필요한 부분만 떠서
data/scenarios/base/world_208.json을 만든다(설계: docs/battle-core/WORLD-MAP-LINK.md).

- 본편 값(좌표·ID·이름·경계)은 고치지 않는다. 항로 곡선만 표시용으로 점을 솎는다.
- 208년 세력 배치는 본편 star-map.md §6.1을 옮긴 것이다(본편 데이터에 권역별 초기 소유 표가 아직 없다).
- 결과 연출(권역 소유 변화)은 이 파일의 outcome_owners가 정한다. 저장하지 않는 연출 값이다.

실행: python tools/scenario/make_world_208.py [본편 경로]
      본편 경로를 생략하면 환경변수 SEONGHANJI_ROOT, 그다음 C:\\WorkSpace\\Seonghanji를 쓴다.
"""
import hashlib, json, os, subprocess, sys
from pathlib import Path

DEFAULT_SRC = r"C:\WorkSpace\Seonghanji"
SRC = Path(sys.argv[1] if len(sys.argv) > 1 else os.environ.get("SEONGHANJI_ROOT", DEFAULT_SRC))
MAP = SRC / "data" / "maps" / "galaxy-map.json"
OUT = Path(__file__).resolve().parent.parent.parent / "data" / "scenarios" / "base" / "world_208.json"

# star-map.md §6.1 시나리오 3 — 적벽 전야(208). 세력 키는 UI Factions와 같다(wei/wu/shu), 나머지는 other.
SYSTEM_OWNERS_208 = {
    "SYS-01": "wei", "SYS-02": "wei", "SYS-03": "wei", "SYS-04": "wei", "SYS-05": "wei",
    "SYS-06": "wei", "SYS-07": "wei", "SYS-08": "wei", "SYS-14": "wei",
    "SYS-15": "wu", "SYS-16": "contested",          # 회남: 손권 일부
    "SYS-13": "contested",                           # 형주: 양양 위, 강하 손, 남부 4군 유비
    "SYS-11": "other", "SYS-12": "other", "SYS-09": "other", "SYS-10": "other",
    "SYS-17": "other", "SYS-18": "other", "SYS-19": "none",
}
SYSTEM_HOLDERS_208 = {   # 표시용 세력 이름(other/none)
    "SYS-11": "유장", "SYS-12": "장로", "SYS-09": "마등·한수", "SYS-10": "마등·한수",
    "SYS-17": "사섭", "SYS-18": "공손강", "SYS-19": "미개척", "SYS-16": "조조·손권", "SYS-13": "삼분",
}
REGION_OWNERS_208 = {"RGN-01": "wei", "RGN-02": "contested", "RGN-03": "shu", "RGN-04": "contested"}
REGION_LABELS = {
    "RGN-01": "양양·번성", "RGN-02": "강릉·강하·공안", "RGN-03": "장사·무릉·계양·영릉", "RGN-04": "구지·태음·형혹",
}
# 결과 연출(BattleOutcome.kind → 권역 소유). 후일담 6(강릉 함락)·9(유비 4군)·J-D7(조조 도강) 근거.
OUTCOME_OWNERS = {
    "alliance_win": {"RGN-01": "wei", "RGN-02": "wu", "RGN-03": "shu", "RGN-04": "wu"},
    "alliance_limited": {"RGN-01": "wei", "RGN-02": "contested", "RGN-03": "shu", "RGN-04": "contested"},
    "cao_win": {"RGN-01": "wei", "RGN-02": "wei", "RGN-03": "wei", "RGN-04": "wei"},
}
# 전장 가장자리 방위 표식과 출격 연출의 진입 방향(BattleBrief.edge_labels)
EDGE_LABELS = {"cao_exit": "장강 대항로", "cao_side": "오림", "alliance_exit": "강하", "alliance_side": "적벽"}
# 장강 대항로로 강조할 항로(남양 → 형주 → 오회)
YANGTZE_PAIRS = [("SYS-14", "SYS-13"), ("SYS-13", "SYS-15")]


def r2(v):
    return [round(v[0], 1), round(v[1], 1)]


def thin(line, keep=14):
    if len(line) <= keep:
        return [r2(p) for p in line]
    step = (len(line) - 1) / (keep - 1)
    return [r2(line[round(i * step)]) for i in range(keep)]


def main():
    raw = MAP.read_bytes()
    g = json.loads(raw)
    systems = [{
        "id": s["id"], "name": s["name"], "display_name": s.get("display_name", ""), "grade": s.get("grade", ""),
        "pos": r2(s["position"]), "owner": SYSTEM_OWNERS_208[s["id"]], "holder": SYSTEM_HOLDERS_208.get(s["id"], ""),
    } for s in g["systems"]]
    yz = {tuple(sorted(p)) for p in YANGTZE_PAIRS}
    routes = []
    for r in g["routes"]:
        a, b = r["connects"]
        if not (a.startswith("SYS-") and b.startswith("SYS-")):
            continue
        routes.append({"id": r["id"], "a": a, "b": b, "kind": r.get("kind", ""),
                       "yangtze": tuple(sorted((a, b))) in yz, "line": thin(r["line"])})
    regions = [{
        "id": r["id"], "name": r["name"], "label": REGION_LABELS[r["id"]], "pos": r2(r["position"]),
        "boundary": [r2(p) for p in r["boundary"]], "owner": REGION_OWNERS_208[r["id"]],
    } for r in g["regions"] if r["system"] == "SYS-13"]
    bodies = [{
        "id": b["id"], "name": b["name"], "kind": b["kind"], "pos": r2(b["position"]),
        "radius": b.get("visual_radius", 5),
    } for b in g["bodies"] if b.get("region") == "RGN-04"]
    try:
        head = subprocess.check_output(["git", "-C", str(SRC), "rev-parse", "HEAD"], text=True).strip()
    except Exception as e:
        head = f"unknown ({e})"
    out = {
        "schema_version": 1,
        "note": "make_world_208.py가 만든다. 직접 고치지 않는다. 설계: docs/battle-core/WORLD-MAP-LINK.md",
        "source": {"map_id": g["map_id"], "map_version": g["map_version"], "asset_version": g["asset_version"],
                   "map_sha256": hashlib.sha256(raw).hexdigest()[:16], "source_head": head},
        "era": "건안 13년 겨울 (208)",
        "world_size": g["world_size"],
        "focus": {"system": "SYS-13", "region": "RGN-04", "body": "BODY-RGN-04-01",
                  "advance_from": "SYS-14", "east_to": "SYS-15"},
        "systems": systems, "routes": routes, "regions": regions, "bodies": bodies,
        "edge_labels": EDGE_LABELS, "outcome_owners": OUTCOME_OWNERS,
    }
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"{len(systems)} systems, {len(routes)} routes, {len(regions)} regions, {len(bodies)} bodies -> {OUT}")


if __name__ == "__main__":
    main()
