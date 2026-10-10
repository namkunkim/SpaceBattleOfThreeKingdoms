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
	print("TERRAIN_DISPLAY_PASS")
	quit(0)
