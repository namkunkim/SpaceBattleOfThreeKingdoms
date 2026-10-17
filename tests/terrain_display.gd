extends SceneTree

# 지형 표시: 오버레이가 그리는 구역이 코어가 쓰는(전장 확대 후) 사각형·이동 배율과 같고, 정본 JSON의 3구역을 모두 포함한다(헤드리스).

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 6:
		await process_frame
	var ov: TacticalOverlay = battle.presentation.hud.overlay
	var zs: Array = ov.terrain_zones()
	var src: BattleSource = battle.presentation.src
	var radar: RadarScope = battle.presentation.hud.radar
	if not TestCheck.ok(self, zs.size() == 3, "구역 3개 (%d)" % zs.size()): return
	var canon: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/scenarios/base/red-cliffs-terrain-rules.json")).zones
	for z in zs:
		var core_z: Dictionary = {}
		for q in battle.sim.terrain.zones:
			if q.id == z.id:
				core_z = q
		if not TestCheck.ok(self, not core_z.is_empty() and z.rect == core_z.rect, "%s 사각형 = 코어" % z.id): return
		var c: Dictionary = {}
		for q in canon:
			if q.id == z.id:
				c = q
		if not TestCheck.ok(self, not c.is_empty(), "%s 정본에 있음" % z.id): return
		var want := float(c.effects.movement_cost_basis_points) / 10000.0
		if not TestCheck.ok(self, absf(z.mul - want) < 0.0001, "%s 배율 %s = %s" % [z.id, z.mul, want]): return
		# 확대 비율: 시나리오 전장 1600x900 -> FIELD_SIZE (약 x1.06, x1.28)
		var kx: float = battle.FIELD_SIZE.x / 1600.0
		var ky: float = battle.FIELD_SIZE.y / 900.0
		var s: Dictionary = c.shape
		var ex := [s.x * kx, s.y * ky, s.width * kx, s.height * ky]
		for i in 4:
			if not TestCheck.ok(self, absf(z.rect[i] - ex[i]) < 0.5, "%s 확대 좌표 %s vs %s" % [z.id, z.rect, ex]): return
		var rr := radar.terrain_rect(z)
		if not TestCheck.ok(self, rr.position.is_equal_approx(radar._w2r(Vector2(z.rect[0], z.rect[1]))) and rr.size.is_equal_approx(Vector2(z.rect[2], z.rect[3]) * radar._scale()), "%s 미니맵 같은 확대 좌표" % z.id): return
	# 겹친 정적 구역의 정보는 코어와 같고, 사격선은 출발점 밖 구역도 반영한다.
	var a := Vector2(700.0 * battle.FIELD_SIZE.x / 1600.0, 130.0 * battle.FIELD_SIZE.y / 900.0)
	var b := Vector2(900.0 * battle.FIELD_SIZE.x / 1600.0, a.y)
	var effects := src.terrain_effects(a, b)
	if not TestCheck.ok(self, is_equal_approx(effects.move, battle.sim.terrain.move_cost_bp(a) / 10000.0) and effects.sensor == -25 and effects.conceal == 11 and is_equal_approx(effects.range, 0.85 * 0.9) and effects.arc == -15, "겹침 이동max/센서합/은폐합/사거리곱/각합"): return
	var exits := src.escape_points()
	if not TestCheck.ok(self, exits.size() == 2 and exits[0].pos == battle.sim.morale.exit_point(0) and exits[1].pos == battle.sim.morale.exit_point(1), "탈출점 확대 좌표 코어 일치"): return
	var ally = battle.vm.alive(0)[0]
	var waypoints: Array[Vector2] = [a, b]
	TestPoke.fleet(battle, ally, {"has_move": true, "move_to": Vector2(500, 100), "route": waypoints, "strafe": true})
	var route := src.fleet_route(ally)
	if not TestCheck.ok(self, route.size() == 4 and route[2] == a and route[3] == b and src.squadron(ally.id).strafe, "투영 경유점과 평행 이동 전달"): return
	var hidden := BattleViewModel.FleetView.new()
	hidden.side = 1
	hidden.has_move = true
	hidden.route.assign(waypoints)
	if not TestCheck.ok(self, src.fleet_route(hidden).is_empty(), "적 경로 비공개"): return
	var outline := radar.camera_outline()
	if not TestCheck.ok(self, outline.size() == 4 and outline[0] == radar._w2r(battle.s2w(Vector2.ZERO)), "카메라 실제 투영 윤곽"): return
	# 화공 임시 구역을 주입해도 그려지지 않는다
	battle.sim.terrain.zones.append({"id": "TRN-ZFIRE-999", "type": "chain_hazard", "name": "x", "rect": [100.0, 100.0, 50.0, 50.0],
		"move_cost_bp": 15000, "sensor_bp": 0, "conceal": 0, "range_bp": 10000, "arc_deg": 0})
	if not TestCheck.ok(self, ov.terrain_zones().size() == 3, "화공 임시 구역은 그리지 않는다"): return
	if not TestCheck.ok(self, src.terrain_zones().size() == 3 and not src.terrain_legend().contains("TRN-ZFIRE") and src.terrain_effects(Vector2(110, 110)).move == 1.0, "미니맵·효과정보 화공 위치 누수 없음"): return
	var legend: String = battle.presentation.hud.terrain_info.tooltip_text
	if not TestCheck.ok(self, "적운 성운" in legend and "파쇄 잔해대" in legend and "행성 그림자" in legend and "최댓값" in legend and "사거리 곱" in legend, "PC·터치 범례 효과와 겹침 설명"): return
	print("TERRAIN_DISPLAY_PASS")
	quit(0)
