"""Independent P05/P07 data checks. Run with Python 3; no game or writes."""
import json
import math
from pathlib import Path
import runpy
import unittest

ROOT = Path(__file__).resolve().parents[3]
DEFINITION = ROOT / "data/scenarios/p05_p07_first_operation_dev_v1.json"
DESIGN = ROOT / "docs/battle-core/pc-campaign-design"


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def closest_to_origin(start, end):
    delta = tuple(b - a for a, b in zip(start, end))
    norm = sum(component ** 2 for component in delta)
    t = min(1, max(0, -sum(a * d for a, d in zip(start, delta)) / norm)) if norm else 0
    return math.hypot(*(a + t * d for a, d in zip(start, delta)))


def separation(start, end, other_start, other_end):
    return closest_to_origin(tuple(a - b for a, b in zip(start, other_start)),
                             tuple(a - b for a, b in zip(end, other_end)))


def clip(start, target, standoff):
    ratio = standoff / math.dist(start, target)
    return tuple(c + ratio * (p - c) for p, c in zip(start, target))


def refill(stock, ammo, cap, material_cost, progress_ms, need_ms, eligible, seen, key):
    deficit = sum(max(0, limit - current) for current, limit in zip(ammo, cap))
    if (not eligible or progress_ms < need_ms or key in seen or deficit <= 0
            or stock[0] < deficit or stock[1] < material_cost):
        return stock, ammo, seen
    return ((stock[0] - deficit, stock[1] - material_cost),
            tuple(max(current, limit) for current, limit in zip(ammo, cap)), seen | {key})


def arrival(sample_ms, schedule, blocked):
    return next((time for time in sample_ms if time > schedule and time not in blocked), None)


def settle(policy, now, *, withdrawing=False, finalize=False, command_lost=False,
           c_control=False, facility_active=False, ever_secured=False, exits=()):
    if command_lost:
        return "failure"
    if not withdrawing and c_control and facility_active and now <= policy["deadline_ms"]:
        return "objective_success"
    if withdrawing and (finalize or now >= policy["deadline_ms"]):
        timely = [(fleet, count) for fleet, count, time in exits
                  if time <= min(now, policy["deadline_ms"])]
        if (ever_secured and any(fleet == policy["command_fleet_id"] for fleet, _ in timely)
                and sum(count for _, count in timely) * 10000
                >= 60 * policy["withdrawal_min_survival_bp"]):
            return "withdrawal_success"
        return "failure"
    return "failure" if now >= policy["deadline_ms"] else None


class CandidateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.definition = load(DEFINITION)
        cls.space = cls.definition["space"]
        cls.nodes = cls.space["nodes"]
        cls.fleets = cls.definition["fleets"]
        cls.padded = [fleet["outer_radius"] + cls.space["center_tolerance"] + cls.space["safety_margin"]
                      for fleet in cls.fleets]

    def source(self, field):
        value = self.definition["inputs"][field]
        self.assertTrue(value.startswith("res://"))
        return load(ROOT / value.removeprefix("res://"))

    def test_version_and_adoption(self):
        d = self.definition
        self.assertEqual((d["schema"], d["status"]),
                         ("p05-p07-first-operation/1", "development_candidate"))
        self.assertEqual((self.space["kind"], self.space["transform"], self.space["origin"]),
                         ("source", "identity", [0, 0]))
        self.assertEqual(self.space["envelope"], "p05-layout-disks-v1")
        self.assertEqual(set(d["product_adoption_required"]),
                         {"difficulty_id", "space", "fleets", "capture", "supply", "reinforcement", "settlement"})
        self.assertTrue(self.source("movement_rules"))

    def test_exact_p05_source_and_envelopes(self):
        access = runpy.run_path(str(DESIGN / "p05_map_access_validation_20261109.py"))
        self.assertEqual(self.nodes, {key: list(value) for key, value in access["NODES"].items()})
        self.assertEqual(self.space["size"], [access["WIDTH"], access["HEIGHT"]])
        for field, ref in (("center_tolerance", "TRACK"), ("safety_margin", "NUMERIC"),
                           ("center_inset", "EDGE"), ("corridor_half_width", "HALF_CORRIDOR"),
                           ("ally_pair_offset", "PAIR_OFFSET")):
            with self.subTest(field=field):
                self.assertEqual(self.space[field], access[ref])
        regions = self.space["regions"]
        self.assertEqual(regions, {"E": {"deployment_radius": access["E_DEPLOY"], "exit_radius": access["E_EXIT"]},
                                  "A": {"service_radius": access["SUPPLY"]}, "B": {"service_radius": access["SUPPLY"]},
                                  "C": {"objective_radius": access["C_GOAL"]}, "R": {"deployment_radius": access["R_DEPLOY"]}})
        probe = runpy.run_path(str(DESIGN / "p05_formation_envelope_probe_20261109.py"))
        roster = {fleet["id"]: fleet for fleet in self.source("roster")["squadrons"]}
        bounds = probe["measure"]()
        self.assertEqual([fleet["id"] for fleet in self.fleets], list(probe["CASES"]))
        for fleet in self.fleets:
            with self.subTest(fleet=fleet["id"]):
                count, formations = probe["CASES"][fleet["id"]]
                row = roster[fleet["roster_id"]]
                self.assertEqual(fleet["id"], fleet["roster_id"])
                self.assertEqual(fleet["ship_count"], count)
                self.assertEqual(sum(ship["count"] for ship in row["composition"]), count)
                self.assertEqual(fleet["formation_id"], row["formation_id"])
                self.assertEqual(fleet["allowed_formations"], list(formations))
                self.assertAlmostEqual(fleet["outer_radius"], bounds[fleet["id"]]["max_transition_order_independent"])

    def test_routes_fit_in_both_directions(self):
        regions = self.space["regions"]
        routes = self.space["routes"]
        offset = self.space["ally_pair_offset"]
        margin = self.space["center_tolerance"] + self.space["safety_margin"]
        self.assertEqual([fleet["offset_xy"] for fleet in self.fleets], [[0, -offset], [0, offset], [0, 0], [0, 0]])
        self.assertEqual([(fleet["spawn"], fleet["side"]) for fleet in self.fleets],
                         [("E", 0), ("E", 0), ("C", 1), ("R", 1)])
        self.assertGreaterEqual(2 * offset, sum(self.padded[:2]))
        self.assertGreaterEqual(regions["E"]["deployment_radius"], offset + max(self.padded[:2]))
        self.assertGreaterEqual(regions["E"]["exit_radius"], offset + margin)
        self.assertGreaterEqual(regions["R"]["deployment_radius"], self.padded[3])
        for name, node_ids, service in (("front", "EJAC", "A"), ("flank", "EJBDC", "B"),
                                        ("reinforcement", "RC", None)):
            with self.subTest(route=name):
                route = routes[name]
                self.assertEqual(route["nodes"], list(node_ids))
                self.assertEqual(route.get("service"), service)
                points = [self.nodes[key] for key in node_ids]
                points[-1] = clip(points[-2], points[-1], route["approach_standoff"])
                if service:
                    self.assertGreaterEqual(regions[service]["service_radius"], offset + margin)
                active = (0, 1) if service else (3,)
                for index in active:
                    radius = self.padded[index]
                    dx, dy = self.fleets[index]["offset_xy"]
                    self.assertGreaterEqual(self.space["corridor_half_width"], math.hypot(dx, dy) + radius)
                    path = [(x + dx, y + dy) for x, y in points]
                    width, height = self.space["size"]
                    for x, y in path:
                        self.assertGreaterEqual(min(x, y, width - x, height - y),
                                                max(radius, self.space["center_inset"] + margin))
                    self.assertLessEqual(math.dist(path[-1], self.nodes["C"]) + margin,
                                         regions["C"]["objective_radius"])
                    for leg in (path, path[::-1]) if service else (path,):
                        for start, end in zip(leg, leg[1:]):
                            self.assertGreaterEqual(separation(start, end, self.nodes["C"], self.nodes["C"]),
                                                    radius + self.padded[2])

    def test_geometry_counterexamples(self):
        self.assertLess(60, self.fleets[0]["outer_radius"])
        self.assertLess(20, self.space["center_inset"])
        self.assertGreater(math.dist((-10, 0), (10, 0)), 2)
        self.assertEqual(separation((-10, 0), (10, 0), (10, 0), (-10, 0)), 0)

    def test_m8_settings_and_transaction_boundaries(self):
        supply = self.definition["supply"]
        m8 = self.source("combat_rules")["combat"]["supply"]
        self.assertEqual((supply["stationary_ms"], supply["still_eps_per_s"], supply["materials_per_refill"],
                          supply["rate_bp"], supply["priority"]),
                         (m8["stationary_s"] * 1000, m8["still_eps_px_s"], m8["materials_per_refill"],
                          m8["throughput_bp"]["operational"], m8["priority"]))
        for facility in ("A", "B"):
            stock = supply["stock_by_facility"][facility]
            available = (stock["ammo"], stock["materials"])
            cost, need = supply["materials_per_refill"], supply["stationary_ms"]
            key = ("op", facility, 1, self.fleets[0]["id"], 1)
            ammo, cap = (90, 11), (100, 10)
            initial = available, ammo, set()
            for elapsed, eligible in ((need - 1, True), (need, False)):
                self.assertEqual(refill(available, ammo, cap, cost, elapsed, need, eligible, set(), key), initial)
            paid = refill(available, ammo, cap, cost, need, need, True, set(), key)
            self.assertEqual(paid, ((available[0] - 10, available[1] - cost), (100, 11), {key}))
            self.assertEqual(refill(paid[0], ammo, cap, cost, need, need, True, paid[2], key),
                             (paid[0], ammo, paid[2]))
            other = ("op", facility, 1, self.fleets[1]["id"], 1)
            last = refill((10, cost), ammo, cap, cost, need, need, True, set(), key)
            self.assertEqual(refill(last[0], ammo, cap, cost, need, need, True, last[2], other),
                             ((0, 0), ammo, {key}))
            self.assertEqual(refill((9, cost), ammo, cap, cost, need, need, True, set(), key),
                             ((9, cost), ammo, set()))

    def test_roster_ammo_deficits_can_use_either_facility(self):
        d = self.definition
        combat = self.source("combat_rules")["combat"]
        roster = {fleet["id"]: fleet for fleet in self.source("roster")["squadrons"]}
        supply = d["supply"]
        for fleet in self.fleets[:2]:
            composition = roster[fleet["roster_id"]]["composition"]
            counts = {row["ship_type_id"]: row["count"] for row in composition}
            equipment = {row.get("mission_equipment_id") for row in composition}
            cap = []
            for category in combat["categories"]:
                weapon = combat["weapons"][category]
                platforms = sum(counts.get(kind, 0) for kind in weapon["platforms"])
                if equipment.intersection(weapon["equipment"]):
                    platforms += counts.get(combat["fast_craft"]["ship_type_id"], 0)
                per_platform = (weapon["ammo_per_platform"] if weapon["shot"]["ammo"] > 0
                                else weapon["special_per_platform"])
                cap.append(platforms * per_platform)
            initial = [limit * fleet["initial_ammo_bp"] // 10000 for limit in cap]
            deficit = sum(cap) - sum(initial)
            self.assertGreater(deficit, 0)
            for stock in supply["stock_by_facility"].values():
                self.assertGreaterEqual(stock["ammo"], deficit)
                self.assertGreaterEqual(stock["materials"], supply["materials_per_refill"])

    def test_reinforcement_and_settlement_boundaries(self):
        r, policy = (self.definition[key] for key in ("reinforcement", "settlement"))
        self.assertEqual(r["fleet_id"], self.fleets[3]["id"])
        self.assertEqual(r["time_comparison"], "gt")
        self.assertEqual(r["blocked"], "wait_for_legal_r_placement")
        self.assertEqual(policy["command_fleet_id"], self.fleets[0]["id"])
        self.assertEqual(sum(fleet["ship_count"] for fleet in self.fleets[:2]), 60)
        deadline, schedule = policy["deadline_ms"], r["scheduled_ms"]
        self.assertGreater(deadline, schedule)
        self.assertIsNone(arrival([schedule - 1, schedule], schedule, set()))
        self.assertEqual(arrival([schedule, schedule + 1], schedule, set()), schedule + 1)
        self.assertEqual(arrival([schedule, schedule + 1, schedule + 2], schedule, {schedule + 1}), schedule + 2)
        goal = {"c_control": True, "facility_active": True}
        self.assertEqual(settle(policy, deadline, **goal), "objective_success")
        self.assertEqual(settle(policy, deadline, command_lost=True, **goal), "failure")
        self.assertIsNone(settle(policy, deadline - 1, c_control=True, ever_secured=True))
        command = policy["command_fleet_id"]
        retreat = {"withdrawing": True, "ever_secured": True, **goal}
        self.assertIsNone(settle(policy, deadline - 1, **retreat))
        minimum = math.ceil(60 * policy["withdrawal_min_survival_bp"] / 10000)
        self.assertEqual(settle(policy, deadline, exits=[(command, minimum, deadline)], **retreat),
                         "withdrawal_success")
        for exits in ([(command, minimum - 1, deadline)], [(command, minimum, deadline + 1)],
                      [(self.fleets[1]["id"], minimum, deadline)]):
            self.assertEqual(settle(policy, deadline, exits=exits, **retreat), "failure")


if __name__ == "__main__":
    unittest.main(verbosity=2)

