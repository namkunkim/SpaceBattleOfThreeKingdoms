extends SceneTree

# 사거리 고리: 투영의 아군 전대 `ranges`가 combat_m3.json 플랫폼 사거리의 범주별 최대값이고, 적 전대에는 없다(헤드리스).

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var F := SalvoFixture
	var cb := F.combat()
	var comp := [["SHP-02", 4], ["SHP-03", 4], ["SHP-04", 4]]
	var s := F.sim([F.def("A", 400, 450, comp, true)], [F.def("B", 1200, 450, [["SHP-03", 4]], true)])
	var proj := BattleProjection.build(s, 0)
	var mine: Dictionary = {}
	var foe: Dictionary = {}
	for q in proj.squadrons:
		if q.side == 0:
			mine = q
		else:
			foe = q
	if not TestCheck.ok(self, mine.has("ranges") and not foe.has("ranges"), "ranges는 아군 전대에만"): return
	var want := {}
	for cat in cb.categories:
		for t in cb.weapons[cat].platforms:
			if t in ["SHP-02", "SHP-03", "SHP-04"]:
				want[cat] = maxf(want.get(cat, 0.0), float(cb.weapons[cat].platforms[t].range))
	if not TestCheck.ok(self, mine.ranges.size() > 0 and mine.ranges == want, "데이터 값과 같다 %s / %s" % [mine.ranges, want]): return
	if not TestCheck.ok(self, mine.ranges.artillery == float(cb.weapons.artillery.platforms["SHP-03"].range) and mine.ranges.artillery > mine.ranges.line_fire, "포격 > 전열, 포격은 SHP-03 사거리"): return
	if not TestCheck.ok(self, mine.range == mine.ranges.values().max(), "range는 범주 최대"): return
	print("RANGE_RINGS_PASS")
	quit(0)
