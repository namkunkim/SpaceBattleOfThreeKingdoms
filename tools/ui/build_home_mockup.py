"""홈 화면 목업(docs/ui/mockup-home-v1.html, v2.html)을 만든다.

본편 data/maps/galaxy-map.json에서 지도 표시에 필요한 것만 줄여 뽑아
tools/ui/home_v*_template.html의 /*MAP_DATA*/ 자리에 넣는다. 값을 고치지 않는다.
실행: python tools/ui/build_home_mockup.py [본편 경로]   (기본 C:\\WorkSpace\\Seonghanji)
"""
import base64, hashlib, json, sys
from pathlib import Path

SRC = Path(sys.argv[1] if len(sys.argv) > 1 else r"C:\WorkSpace\Seonghanji")
HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
PAGES = [("home_v1_template.html", "mockup-home-v1.html"), ("home_v2_template.html", "mockup-home-v2.html")]
MAP = SRC / "data" / "maps" / "galaxy-map.json"


def rdp(pts, eps):
    """Ramer-Douglas-Peucker 단순화."""
    if len(pts) < 3:
        return pts
    (x1, y1), (x2, y2) = pts[0], pts[-1]
    dx, dy = x2 - x1, y2 - y1
    norm = (dx * dx + dy * dy) ** 0.5 or 1.0
    best, idx = -1.0, 0
    for i in range(1, len(pts) - 1):
        x, y = pts[i]
        d = abs(dy * x - dx * y + x2 * y1 - y2 * x1) / norm
        if d > best:
            best, idx = d, i
    if best > eps:
        return rdp(pts[: idx + 1], eps)[:-1] + rdp(pts[idx:], eps)
    return [pts[0], pts[-1]]


def ints(pts):
    return [[round(x), round(y)] for x, y in pts]


g = json.loads(MAP.read_text(encoding="utf-8"))
field = g["field"]
data = {
    "source": {
        "file": "Seonghanji/data/maps/galaxy-map.json",
        "map_version": g["map_version"],
        "asset_version": g["asset_version"],
        "sha256_16": hashlib.sha256(MAP.read_bytes()).hexdigest()[:16],
    },
    "world": g["world_size"],
    "systems": [[s["id"], s["name"], s["display_name"], s["grade"], round(s["position"][0]), round(s["position"][1])]
                for s in g["systems"]],
    "regions": [[r["id"], r["name"], r["system"], bool(r.get("is_seat")), round(r["position"][0]), round(r["position"][1]),
                 ints(r["boundary"])]
                for r in g["regions"]],
    "routes": [[r["id"], r["kind"], r["display_policy"], r.get("corridor"), ints(rdp([tuple(p) for p in r["line"]], 25))]
               for r in g["routes"]],
    "corridors": [[c["id"], c["name"], c["scale"], round(c["position"][0]), round(c["position"][1]), ints(c["passage_axis"])]
                  for c in g["corridors"]],
    "external": [[e["id"], round(e["position"][0]), round(e["position"][1])] for e in g["external_nodes"]],
    "solar": [[b["id"], b["name"], b["kind"], b["position"][0], b["position"][1], b.get("visual_radius", 4)]
              for b in g["bodies"] if b["region"] == "RGN-04"],
    "terrain_labels": [[t["name"], round((t["bounds"][0] + t["bounds"][2]) / 2), round((t["bounds"][1] + t["bounds"][3]) / 2)]
                       for t in g["terrain"] if "개방" not in t["name"] and "분지" not in t["name"] and "평원" not in t["name"]],
    "field": {
        "cell": field["cell_size"], "cols": field["cols"], "rows": field["rows"],
        "density": base64.b64encode(bytes(max(0, min(255, int(v))) for v in field["density"])).decode(),
        "gas": base64.b64encode(bytes(max(0, min(255, int(v))) for v in field["gas"])).decode(),
    },
}
payload = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
for tpl, out in PAGES:
    if not (HERE / tpl).exists():
        continue
    html = (HERE / tpl).read_text(encoding="utf-8").replace("/*MAP_DATA*/null", payload)
    (ROOT / "docs" / "ui" / out).write_text(html, encoding="utf-8")
    print(out, len(html), "bytes")
