extends SceneTree

# 오버레이 바닥 고리 투영(TacticalOverlay._ground_ring, 프레임당 행렬)이 Camera3D.unproject_position(battle.w2s)과 같은지 본다(헤드리스).
# 카메라 위치·확대·흔들림 오프셋 여러 개, 화면 밖과 카메라 뒤의 점까지 포함한다(REVIEW-PERF-1500 R2).

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 6:
		await process_frame
	var ov: TacticalOverlay = battle.presentation.hud.overlay
	var rig: CameraRig = battle.rig
	var cases := [[Vector2(900, 1150), 0.9, 0.0], [Vector2(300, 400), 0.5, 0.3], [Vector2(3000, 2000), 1.9, -0.4], [Vector2(1700, 1150), 0.3, 0.0]]
	var n := 0
	var behind := 0
	for cs in cases:
		rig.cam_pos = cs[0]
		rig.cam_z = cs[1]
		rig.update()
		rig.camera.h_offset = cs[2]
		rig.camera.v_offset = -cs[2]
		ov._proj_begin()
		# 카메라 바로 밑·뒤를 지나는 큰 고리(카메라 뒤 점 포함)와 화면 안 작은 고리
		for ring in [[cs[0], 60.0], [cs[0] + Vector2(0, 900), 1500.0], [Vector2(100, 100), 4000.0], [cs[0] + Vector2(0, 6000), 400.0]]:
			var c: Vector2 = ring[0]
			var r: float = ring[1]
			var pts := ov._ground_ring(c, r, 48)
			for i in pts.size():
				var a := TAU * i / 48
				var want: Vector2 = battle.w2s(c + Vector2(cos(a), sin(a)) * r)
				var tol := maxf(0.01, want.length() * 1e-5)
				if not TestCheck.ok(self, pts[i].distance_to(want) <= tol, "투영 일치 %s r%.0f #%d: %s vs %s" % [c, r, i, pts[i], want]): return
				n += 1
				var q := c + Vector2(cos(a), sin(a)) * r
				var v: Vector4 = ov._pm * Vector4((q.x - CameraRig.WORLD.x * 0.5) * CameraRig.S, 0.0, (q.y - CameraRig.WORLD.y * 0.5) * CameraRig.S, 1.0)
				if v.w <= 0.0:
					behind += 1
	if not TestCheck.ok(self, behind > 0, "카메라 뒤 점 포함 (%d)" % behind): return
	rig.camera.h_offset = 0.0
	rig.camera.v_offset = 0.0
	print("ground_ring_proj: %d점 일치, 카메라 뒤 %d점" % [n, behind])
	print("GROUND_RING_PROJ_PASS")
	quit(0)
