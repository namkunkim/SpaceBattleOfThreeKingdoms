"""본편 은하맵에서 성역·권역·행성·항로·지형을 뽑아 전체 맵 시안 HTML에 넣는다.

사용: python tools/ui/make_galaxy_full_data.py <본편 폴더>
결과: docs/ui/mockup-galaxy-map-full-v1.html 안의 /*DATA*/ ... /*END*/ 구간을 바꾼다.
소유는 본편 star-map.md §6.1(208 적벽 전야)이다. 강릉=위는 컨셉 추정(GALAXY-MAP-REDESIGN.md §4).
"""
import json, re, sys
from pathlib import Path

SRC = Path(sys.argv[1] if len(sys.argv) > 1 else r"C:\WorkSpace\Seonghanji")
HTML = Path(__file__).resolve().parents[2] / "docs/ui/mockup-galaxy-map-full-v1.html"

m = json.loads((SRC / "data/maps/galaxy-map.json").read_text(encoding="utf-8"))
regions_src = {r["id"]: r for r in json.loads((SRC / "data/regions.json").read_text(encoding="utf-8"))}
systems_src = {s["id"]: s for s in json.loads((SRC / "data/systems.json").read_text(encoding="utf-8"))}

# 208 소유: 성역 단위 기본값, 권역 단위 예외
SYS_OWNER = {"SYS-01": "wei", "SYS-02": "wei", "SYS-03": "wei", "SYS-04": "wei", "SYS-05": "wei", "SYS-06": "wei",
             "SYS-07": "wei", "SYS-08": "wei", "SYS-14": "wei", "SYS-16": "wei", "SYS-15": "wu",
             "SYS-11": "zhang", "SYS-12": "lu", "SYS-09": "ma", "SYS-10": "ma", "SYS-17": "xie", "SYS-18": "kang",
             "SYS-19": "none", "SYS-13": "wei"}
RGN_OWNER = {"RGN-01": "wei", "RGN-02": "split", "RGN-03": "shu", "RGN-04": "war"}
CITY_OWNER = {"강하": "shu", "구지": "war", "형혹": "war", "태음": "war"}


def r1(v):
    return round(v)


def thin(pts, step):
    out = pts[::step]
    if out[-1] != pts[-1]:
        out.append(pts[-1])
    return [[r1(x), r1(y)] for x, y in out]


def owner_of(rid, sid):
    return RGN_OWNER.get(rid, SYS_OWNER[sid])


data = {"world": m["world_size"], "systems": [], "regions": [], "cities": [], "routes": [], "corridors": [], "terrain": [],
        "external": [{"name": "서역", "at": [r1(v) for v in n["position"]]} for n in m["external_nodes"]]}
for s in m["systems"]:
    src = systems_src[s["id"]]
    data["systems"].append({"id": s["id"], "name": s["name"], "full": s["display_name"], "grade": s["grade"],
                            "at": [r1(v) for v in s["position"]], "regions": s["regions"], "owner": SYS_OWNER[s["id"]],
                            "capitals": src["terran_planets"]})
for r in m["regions"]:
    src = regions_src[r["id"]]
    data["regions"].append({"id": r["id"], "name": r["name"], "sys": r["system"], "seat": bool(r["is_seat"]),
                            "at": [r1(v) for v in r["position"]], "poly": [[r1(x), r1(y)] for x, y in r["boundary"]],
                            "owner": owner_of(r["id"], r["system"]), "income": src["income"], "pop": src["population"],
                            "prod": src["production"], "def": src["defense"], "st": src["strongholds"],
                            "rt": src["routes_hosted"], "note": src.get("notes")})
for b in m["bodies"]:
    if b.get("economic_entity") is False or b["kind"] in ("star",):
        continue
    reg = next(r for r in data["regions"] if r["id"] == b["region"])
    own = CITY_OWNER.get(b["name"], "wei" if reg["owner"] == "split" else reg["owner"])
    data["cities"].append({"name": b["name"], "at": [r1(v) for v in b["position"]], "kind": b["kind"],
                           "rgn": b["region"], "owner": own})
# 행성계: 거주 주행성마다 항성·내행성·금성형·위성·외행성이 붙는다(본편 planetary_families 22개).
by_id = {b["id"]: b for b in m["bodies"]}
data["bodies"] = []
for b in m["bodies"]:
    reg = next(r for r in data["regions"] if r["id"] == b["region"])
    own = CITY_OWNER.get(b["name"], "wei" if reg["owner"] == "split" else reg["owner"])
    parent = b.get("parent_body") or b.get("parent_star")
    data["bodies"].append({"id": b["id"], "name": b["name"], "kind": b["kind"], "role": b.get("role"),
                           "at": [round(v, 1) for v in b["position"]], "r": b["visual_radius"], "rgn": b["region"],
                           "eco": b.get("economic_entity", True) is not False, "seed": b.get("shape_seed", 0) % 997,
                           "parent": parent, "owner": own})
data["families"] = [{"id": f["id"], "host": f["host"], "star": f["star"], "at": [r1(v) for v in by_id[f["star"]]["position"]],
                     "center": [r1(v) for v in f["position"]], "radius": f["radius"],
                     "name": by_id[f["host"]]["name"]} for f in m["planetary_families"]]
for rt in m["routes"]:
    data["routes"].append({"id": rt["id"], "kind": rt["kind"], "connects": rt["connects"], "corridor": rt["corridor"],
                           "line": thin(rt["line"], 3)})
for c in m["corridors"]:
    data["corridors"].append({"id": c["id"], "name": c["name"], "at": [r1(v) for v in c["position"]],
                              "barrier": [[r1(x), r1(y)] for x, y in c["barrier_axis"]], "w": c["barrier_half_width"],
                              "scale": c.get("scale")})
for t in m["terrain"]:
    polys = [[thin(ring, 1) for ring in poly] for poly in t["polygons"]]
    data["terrain"].append({"name": t["name"], "kind": t["kind"], "density": t["density_peak"], "gas": t.get("gas_peak") or 0,
                            "polys": polys})

# 적벽 전대: 이 저장소의 시나리오 정본(배치 좌표·진형·함종 편성). 전장 좌표 0..1600×0..900.
ROOT = Path(__file__).resolve().parents[2]
sc = json.loads((ROOT / "data/scenarios/red_cliffs_208_realtime.json").read_text(encoding="utf-8"))
frm = json.loads((ROOT / "data/scenarios/base/formations.json").read_text(encoding="utf-8"))
frm = {f["id"]: f["name"] for f in (frm if isinstance(frm, list) else frm.get("formations", []))}
SIDE = {"liu_bei": "shu", "sun_quan": "wu", "cao_cao": "wei"}
data["squadrons"] = [{
    "id": q["id"], "f": SIDE[q["faction_id"]], "name": q["name"], "cmd": q["commander"]["name"],
    "vice": (q.get("vice_commander") or {}).get("name"), "staff": [x["name"] for x in q.get("staff", [])],
    "pos": q["initial_position"], "flag": bool(q.get("flagship")), "frm": q.get("formation_id"),
    "frm_name": frm.get(q.get("formation_id"), ""), "delay": q.get("deploy_delay_s", 0),
    "comp": [[c["ship_type_id"], c["count"]] for c in q["composition"]],
} for q in sc["squadrons"]]

blob = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
html = HTML.read_text(encoding="utf-8")
html = re.sub(r"/\*DATA\*/.*?/\*END\*/", lambda _: "/*DATA*/" + blob + "/*END*/", html, flags=re.S)
HTML.write_text(html, encoding="utf-8")
print(f"{HTML.name}: data {len(blob)//1024} KB, systems {len(data['systems'])}, regions {len(data['regions'])}, "
      f"cities {len(data['cities'])}, bodies {len(data['bodies'])}, families {len(data['families'])}, routes {len(data['routes'])}, terrain {len(data['terrain'])}")
