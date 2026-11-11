"""P05 offline witness checks. Reads only P05 envelope inputs; writes to stdout."""

import json
import math
import runpy
from pathlib import Path


HERE = Path(__file__).resolve().parent
NODES = dict(E=(250, 830), J=(520, 490), A=(895, 240), B=(690, 875),
             D=(1060, 865), C=(1320, 640), R=(1450, 290))
WIDTH, HEIGHT, EDGE = 1700, 1150, 40
TRACK, NUMERIC = 2.0, 1.0
HALF_CORRIDOR = 155.0
PAIR_OFFSET = 67.0
C_DEFENDER_DISTANCE = 245.0
R_DEFENDER_DISTANCE = 155.0
E_DEPLOY, E_EXIT, SUPPLY, R_DEPLOY, C_GOAL = 155.0, 75.0, 75.0, 60.0, 320.0


def distance(a, b):
    return math.dist(a, b)


def margin_to_box(point, inset=0.0):
    x, y = point
    return min(x, y, WIDTH - x, HEIGHT - y) - inset


def before_end(start, end, distance_to_end):
    ratio = distance_to_end / distance(start, end)
    assert 0 < ratio < 1
    return tuple(e + (s - e) * ratio for s, e in zip(start, end))


def headings(points):
    return [math.degrees(math.atan2(by - ay, bx - ax))
            for (ax, ay), (bx, by) in zip(points, points[1:])]


def tube_checks(points, outer_radius, center_offset):
    # A closed straight capsule is convex. Its cross-section centered anywhere
    # on the segment contains the swept disk if half-width >= outer_radius.
    # The four world and center-clamp halfspaces need only endpoint checks.
    wall = min(margin_to_box(point) for point in points)
    return dict(corridor=HALF_CORRIDOR - outer_radius, wall=wall - outer_radius,
                core_center_limit=wall - EDGE - center_offset - TRACK - NUMERIC)


def inside_tracking_budget(proposed, planned):
    return distance(proposed, planned) <= TRACK


def main():
    envelope = runpy.run_path(str(HERE / "p05_formation_envelope_probe_20261109.py"))
    values = envelope["measure"]()

    def pad(id):
        return values[id]["max_transition_order_independent"] + TRACK + NUMERIC

    liu1, liu2 = (pad(f"RC-LIU-SQ-0{i}") for i in (1, 2))
    cao4, cao5 = (pad(f"RC-CAO-SQ-0{i}") for i in (4, 5))
    group = PAIR_OFFSET + max(liu1, liu2)
    cases = {}
    c, e = NODES["C"], NODES["E"]
    for route, supply_id in (("EJAC", "A"), ("EJBDC", "B")):
        points = [NODES[node] for node in route]
        points[-1] = before_end(points[-2], c, C_DEFENDER_DISTANCE)
        clearances = tube_checks(points, group, PAIR_OFFSET)
        clearances.update(
            e_deploy=E_DEPLOY - group,
            e_exit=E_EXIT - PAIR_OFFSET - TRACK - NUMERIC,
            service=SUPPLY - PAIR_OFFSET - TRACK - NUMERIC,
            c_goal=C_GOAL - distance(points[-1], c) - PAIR_OFFSET - TRACK - NUMERIC,
            c_defender=distance(points[-1], c) - group - cao4,
            group_interfleet=2 * PAIR_OFFSET - liu1 - liu2,
        )
        # Prior segments lie entirely farther from C than their last endpoint.
        # Verify the closest point on every segment, including the clipped last.
        for start, end in zip(points, points[1:]):
            delta = tuple(b - a for a, b in zip(start, end))
            t = sum((p - a) * d for p, a, d in zip(c, start, delta))
            t = min(1.0, max(0.0, t / sum(d * d for d in delta)))
            closest = tuple(a + t * d for a, d in zip(start, delta))
            assert distance(closest, c) >= group + cao4
        assert all(value >= 0 for value in clearances.values()), (route, clearances)
        cases[route] = dict(points=points, headings_deg=headings(points),
                            return_headings_deg=headings(points[::-1]),
                            service_node=NODES[supply_id], exit_node=e,
                            service_centers=[(NODES[supply_id][0], NODES[supply_id][1] + offset)
                                             for offset in (-PAIR_OFFSET, PAIR_OFFSET)],
                            exit_centers=[(e[0], e[1] + offset)
                                          for offset in (-PAIR_OFFSET, PAIR_OFFSET)],
                            clearance=clearances)

    reinforcement = [NODES["R"], before_end(NODES["R"], c, R_DEFENDER_DISTANCE)]
    clearances = tube_checks(reinforcement, cao5, 0.0)
    clearances.update(r_deploy=R_DEPLOY - cao5,
                      c_goal=C_GOAL - distance(reinforcement[-1], c) - TRACK - NUMERIC,
                      c_defender=distance(reinforcement[-1], c) - cao5 - cao4)
    assert all(value >= 0 for value in clearances.values())
    cases["RC"] = dict(points=reinforcement, headings_deg=headings(reinforcement),
                       clearance=clearances)

    # Closed transverse throat: ordered J-A corridor, no side bypass.
    # Radius uses the accepted disk even before uncertainty inflation.
    throat = 60.0
    j, a = NODES["J"], NODES["A"]
    edge_length = distance(j, a)
    station_bounds = (edge_length / 2 - 20.0, edge_length / 2 + 20.0)
    assert 0 < station_bounds[0] < station_bounds[1] < edge_length
    bare_liu1 = liu1 - TRACK - NUMERIC
    assert throat < bare_liu1 and cases["EJBDC"]["clearance"]["corridor"] > 0
    # Separate service negative: center rule, not full-hull containment.
    # Moving A service center to x=0 and using radius 20 allows only x<=20.
    # Every legal fleet center must satisfy x>=40, independently of hull size.
    bad_service_radius = 20.0
    assert bad_service_radius < EDGE and cases["EJAC"]["clearance"]["corridor"] > 0
    cases["negative"] = dict(
        throat_half_width=throat, required_half_width=bare_liu1,
        throat_station_bounds=station_bounds,
        throat_deficit=bare_liu1 - throat, affected="J-A only",
        inaccessible_service_center=(0, NODES["A"][1]),
        inaccessible_service_radius=bad_service_radius,
        legal_center_gap=EDGE - bad_service_radius, affected_service="A only",
    )

    # Guard arithmetic example; an actual future engine must enforce these per tick.
    dt, speed_cap = 0.1, 20.0
    assert speed_cap * dt == TRACK
    boundary = inside_tracking_budget((2.0, 0.0), (0.0, 0.0))
    outside = inside_tracking_budget((1.5, 1.5), (0.0, 0.0))
    assert boundary and not outside
    cases["guard"] = dict(max_dt=dt, speed_cap=speed_cap, track=TRACK,
                          numeric=NUMERIC, nominal_center_separation=2 * PAIR_OFFSET,
                          group_radius=group, admitted_error_2=boundary,
                          rejected_error_over_2=not outside)
    print(json.dumps(cases, indent=2))


if __name__ == "__main__":
    main()
