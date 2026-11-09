"""Read-only P05 candidate envelope. Run with Python 3 from any directory."""

import json
import math
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
GAP_FWD, GAP_LAT = 25.0, 13.0
SHAPES = {"FRM-01": 7, "FRM-03": 4, "FRM-04": 8}
# Model lengths keyed by ship type. SHP-08 uses the escort silhouette.
CLASS_LENGTH = {
    "SHP-01": 1.25, "SHP-02": 1.2, "SHP-03": 1.0, "SHP-04": 1.15,
    "SHP-05": 0.9, "SHP-06": 0.88, "SHP-07": 0.6, "SHP-08": 0.6,
}
RENDER_ORDER = ("SHP-04", "SHP-02", "SHP-03", "SHP-06",
                "SHP-01", "SHP-05", "SHP-07", "SHP-08")
CASES = {
    "RC-LIU-SQ-01": (39, ("FRM-03", "FRM-01")),
    "RC-LIU-SQ-02": (21, ("FRM-01", "FRM-03")),
    "RC-CAO-SQ-04": (45, ("FRM-04",)),
    "RC-CAO-SQ-05": (30, ("FRM-03",)),
}


def pattern(shape, count):
    if shape == 4:
        points = [(0.0, 0.0)]
        ring = 1
        while len(points) < count:
            for index in range(min(ring * 7, count - len(points))):
                angle = math.tau * index / (ring * 7) + ring * 0.3
                radius = ring * GAP_LAT * 1.25
                points.append((math.cos(angle) * radius, math.sin(angle) * radius))
            ring += 1
        return points
    columns = math.ceil(math.sqrt(count * 3.0))
    points = []
    for index in range(count):
        row, column = divmod(index, columns)
        relative_column = column - (columns - 1) * 0.5
        forward = -row * GAP_FWD
        lateral = relative_column * GAP_LAT
        if shape == 7 and row % 2:
            lateral += GAP_LAT * 0.5
        if shape == 8:
            forward += abs(relative_column) * GAP_FWD * 0.5 - columns * GAP_FWD * 0.1
        points.append((forward, lateral))
    return points


def projected_slots(shape, count):
    base = pattern(shape, (count + 1) // 2)
    points = [
        (base[index // 2][0] + index % 2 * GAP_FWD * 0.5,
         base[index // 2][1] + index % 2 * GAP_LAT * 0.5)
        for index in range(count)
    ]
    center_x, center_y = (sum(axis) / count for axis in zip(*points))
    return [(x - center_x, y - center_y) for x, y in points]


def assign_slots(points, ship_ids, roles):
    lo = min(x for x, _ in points)
    depth = max(1.0, max(x for x, _ in points) - lo)
    width = max(1.0, max(abs(y) for _, y in points))
    free = list(range(len(points)))
    result = [None] * len(points)
    for kind in roles["order"]:
        balance = 0
        front, edge = roles["targets"][kind]

        def score(slot):
            x, y = points[slot]
            side = (y > 0) - (y < 0)
            return (2 * ((x - lo) / depth - front) ** 2
                    + (abs(y) / width - edge) ** 2 + 0.12 * max(0, balance * side))

        for index, ship_id in enumerate(ship_ids):
            if ship_id != kind:
                continue
            selected = min(free, key=score)
            result[index] = points[selected]
            y = points[selected][1]
            balance += (y > 0) - (y < 0)
            free.remove(selected)
    assert not free and None not in result
    return result


def hull_corner_radius(ship_id, flagship):
    scale = CLASS_LENGTH[ship_id] * (1.8 if flagship else 1.0)
    length = scale * 0.75 / 0.05
    width = scale * 0.48 / 1.9 / 0.05
    return math.hypot(length * 0.5, width * 0.5)


def measure():
    scenario = json.loads((ROOT / "data/scenarios/red_cliffs_208_realtime.json").read_text(encoding="utf-8"))
    roster = {fleet["id"]: fleet for fleet in scenario["squadrons"]}
    roles_text = (ROOT / "data/fleet-role-layout.md").read_text(encoding="utf-8")
    roles = json.loads(re.search(r"```fleet-role-layout\s+(.*?)```", roles_text, re.S).group(1))
    bounds = {}
    for fleet_id, (count, formations) in CASES.items():
        fleet = roster[fleet_id]
        counts = {ship["ship_type_id"]: ship["count"] for ship in fleet["composition"]}
        ship_ids = [kind for kind in RENDER_ORDER for _ in range(counts.get(kind, 0))]
        assert len(ship_ids) == count and set(ship_ids) == set(counts)
        starts = assign_slots(projected_slots(SHAPES[formations[0]], count), ship_ids, roles)
        flagship = min(range(count), key=lambda i: math.hypot(*starts[i])) if fleet["flagship"] else -1
        max_hull = max(hull_corner_radius(kind, fleet["flagship"]) for kind in ship_ids)
        rows = []
        for formation in formations:
            points = assign_slots(projected_slots(SHAPES[formation], count), ship_ids, roles)
            slot_max = max(math.hypot(*point) for point in points)
            assigned = [math.hypot(*point) + hull_corner_radius(ship_id, index == flagship)
                        for index, (point, ship_id) in enumerate(zip(points, ship_ids))]
            witness = max(range(count), key=assigned.__getitem__)
            robust = slot_max + max_hull
            assert assigned[witness] <= robust
            rows.append({"formation": formation, "slot_max": slot_max,
                         "assigned_bound": assigned[witness],
                         "witness": [witness, ship_ids[witness], *points[witness]],
                         "order_independent_bound": robust})
        bounds[fleet_id] = {"count": count, "rows": rows, "flagship_slot": flagship,
                            "max_transition_assigned": max(r["assigned_bound"] for r in rows),
                            "max_transition_order_independent": max(r["order_independent_bound"] for r in rows)}
    return bounds


if __name__ == "__main__":
    bounds = measure()
    print(json.dumps(bounds, ensure_ascii=False, indent=2))
    allies = [bounds[fleet]["max_transition_order_independent"] for fleet in tuple(CASES)[:2]]
    print(f"ally_pair_center_separation_without_margin={sum(allies):.6f}")
    print(f"ally_pair_best_center_disk_at_minimum_separation={sum(allies):.6f}")
    print(f"ally_pair_midpoint_disk_at_minimum_separation={sum(allies)/2 + max(allies):.6f}")
