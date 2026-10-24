extends SceneTree

const DEF := "res://data/profiles/red_cliffs_rt.json"
const BEFORE := "res://docs/battle-core/evidence/fleet-size-20261024/fleet-audit.json"

func _initialize() -> void:
	call_deferred("_run")

func _count(d: Dictionary, type: String) -> int:
	var n := 0
	for c in d.composition:
		if c.ship_type_id == type:
			n += int(c.count)
	return n

func _run() -> void:
	var scn := ProfileLoader.read_json(ProfileLoader.read_json(DEF).scenario_path)
	var baseline := ProfileLoader.read_json(BEFORE)
	var report := {}
	for diff in scn.difficulty_order:
		# 기본 정책이 없는 시나리오는 이전 자동 편성으로 돌아가며, 이전 Python 집계도 실제 코어로 교차 확인한다.
		var legacy_scn := scn.duplicate(true)
		legacy_scn.realtime_rules.erase("auto_organization")
		var legacy := Organization.auto_all(ScenarioProfile.load_profile(DEF, diff), legacy_scn)
		for before in baseline[diff]:
			var old: Dictionary = (legacy.ally + legacy.foe).filter(func(r): return r.squadron_id == before.id)[0]
			if not TestCheck.ok(self, old.ships == int(before.ships), "legacy fleet count " + before.id): return
		var p := Organization.load_auto(DEF, diff)
		if not TestCheck.ok(self, not p.is_empty(), "auto profile " + diff): return
		if not TestCheck.ok(self, p == Organization.load_auto(DEF, diff), "deterministic " + diff): return
		if not TestCheck.ok(self, Organization.validate(p.organization, scn, p).is_empty(), "valid " + diff): return
		var before_ally: Array = baseline[diff].filter(func(r): return r.faction != "cao_cao")
		var ally_cost := 0
		var enemy_cost := 0
		var old_budget := 0
		var rows := []
		for fl in p.organization.fleets:
			var d: Dictionary = (p.ally + p.foe).filter(func(r): return r.squadron_id == fl.squadron_id)[0]
			var cost := Organization.cost_of(fl, p)
			var lim := Organization.limit_of(fl, scn, p)
			if not TestCheck.ok(self, cost <= lim, "command limit " + fl.squadron_id): return
			if fl.faction_id == "cao_cao":
				enemy_cost += cost
				var fill := int(p.scenario.difficulty_profile.cao_last_fill_bp) if d == p.foe[-1] else BattleRules.BP
				old_budget += int(lim * fill / BattleRules.BP)
				if int(d.wait) == 360:
					if not TestCheck.ok(self, float(cost) / lim > 0.85 and d.ships >= 45, "rear minimum strength " + fl.squadron_id): return
			else:
				ally_cost += cost
				var before: Dictionary = before_ally.filter(func(r): return r.id == fl.squadron_id)[0]
				if not TestCheck.ok(self, d.ships == int(before.ships) and cost == int(before.cost) and d.name == before.admiral, "allied roster unchanged " + fl.squadron_id): return
				for type in before.composition:
					if not TestCheck.ok(self, _count(d, type) == int(before.composition[type]), "allied mix unchanged " + fl.squadron_id): return
			rows.append({"id":d.squadron_id,"name":d.name,"ships":d.ships,"cost":cost,"limit":lim,"wait":d.wait,"composition":d.composition})
		if not TestCheck.ok(self, enemy_cost <= old_budget and old_budget - enemy_cost < p.foe.size() * 2, "total budget conserved " + diff): return
		if not TestCheck.ok(self, absf(float(enemy_cost) / ally_cost - float(p.scenario.difficulty_profile.target_cost_ratio)) <= 0.05, "cost ratio " + diff): return
		var front: Dictionary = p.foe[1]
		var artillery: Dictionary = p.foe[2]
		var fast: Dictionary = p.foe[5]
		var rear: Dictionary = p.foe[6]
		if not TestCheck.ok(self, _count(front,"SHP-04") > _count(front,"SHP-03") * 2 and _count(front,"SHP-01") > _count(rear,"SHP-01"), "vanguard line and assault emphasis"): return
		if not TestCheck.ok(self, _count(artillery,"SHP-03") > _count(artillery,"SHP-04"), "artillery emphasis"): return
		if not TestCheck.ok(self, _count(fast,"SHP-07") > _count(fast,"SHP-04") * 2, "fast escort emphasis"): return
		if not TestCheck.ok(self, _count(rear,"SHP-05") > _count(front,"SHP-05"), "rear supply emphasis"): return
		report[diff] = {"ally_cost":ally_cost,"enemy_cost":enemy_cost,"budget":old_budget,"rows":rows}
		print("FLEET_SIZE ", diff, " costs=", ally_cost, "/", enemy_cost, " ships=", p.foe.map(func(d): return d.ships))
	var output := FileAccess.open("res://docs/battle-core/evidence/fleet-size-20261024/after.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	print("FLEET_SIZE_REVIEW_PASS")
	quit()
