extends SceneTree

# 함선 슬롯 추종(뷰 전용 연출) 검증. godot --headless --path . --script tests/fleet_follow.gd
# 추종은 전투 상태를 읽기만 하고 난수를 쓰지 않는다. 가짜 전대 사전을 직접 먹여 본다.

var fails := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("FAIL ", what)

func _max_err(r: FleetRenderer, v: FleetRenderer.FleetVis, sq: Dictionary) -> float:
	var fpos := r.src.to3(sq.pos)
	var frot := -float(sq.heading) - PI * 0.5
	var e := 0.0
	for s in v.slots:
		e = maxf(e, s.pos.distance_to(r._target(s, fpos, frot)))
	return e

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 5:
		await process_frame
	var r: FleetRenderer = battle.presentation.renderer
	# 0. 편성이 보이는 전대는 화면 함선 수 = 실제 척 수(함종별 합)
	var n_real := 0
	for sid in r.vis:
		var d: Dictionary = r.src.squadron(sid)
		if d.get("counts", {}).is_empty():
			continue
		n_real += 1
		_check(r.vis[sid].slots.size() == roundi(d.max_ships), "%s 화면 %d척 = 실제 %d척" % [d.name, r.vis[sid].slots.size(), roundi(d.max_ships)])
	_check(n_real > 0, "편성 있는 전대 존재")
	var id: int = r.vis.keys()[0]
	var v: FleetRenderer.FleetVis = r.vis[id]
	var sq := {"id": id, "pos": Vector2(1500, 1000), "heading": 0.0, "formation": v.formation}
	# A. 정지 전대에서 모든 함선이 슬롯에 수렴한다
	for i in 400:
		r._follow(v, sq, 0.05)
	_check(_max_err(r, v, sq) < 0.02, "정지 수렴 err=%.4f" % _max_err(r, v, sq))
	# B. 급선회 뒤 수렴, 이동 중 늘림(M7)과 정지 후 복귀, 함선 방향 공유(M3)
	sq.heading = PI * 0.5
	for i in 600:
		r._follow(v, sq, 0.05)
	_check(_max_err(r, v, sq) < 0.02, "선회 후 수렴")
	var yaw0: float = v.slots[0].yaw
	var same_yaw := true
	for s in v.slots:
		same_yaw = same_yaw and is_equal_approx(s.yaw, yaw0)
	_check(same_yaw, "함선 방향 공유")
	var mv := {"id": id, "pos": sq.pos, "heading": sq.heading, "formation": sq.formation}
	for i in 40:
		mv.pos += Vector2(0, 30)
		r._follow(v, mv, 0.05)
	_check(v.stretch > 1.2, "이동 중 간격 늘림 %.2f" % v.stretch)
	for i in 400:
		r._follow(v, mv, 0.05)
	_check(v.stretch == 1.0, "정지 후 간격 복귀")
	sq.pos = mv.pos
	# B2. 조준 중에는 모든 함선이 같은 방향(함대 중심 → 적), 조준이 풀리면 함대 방향으로 돌아온다
	var foe_pos := r.src.to3(sq.pos + Vector2(500.0, 500.0))
	v.aim = true
	v.aim_pos = foe_pos
	for i in 100:
		r._follow(v, sq, 0.05)
	var ay: float = v.slots[0].yaw
	var aim_same := true
	for s in v.slots:
		aim_same = aim_same and is_equal_approx(s.yaw, ay)
	var fh := -float(sq.heading) - PI
	_check(aim_same and absf(wrapf(ay - fh, -PI, PI)) > 0.3, "조준 중 같은 방향(함대 방향과 다름)")
	v.aim = false
	v.rest = 0
	for i in 100:
		r._follow(v, sq, 0.05)
	_check(absf(wrapf(v.slots[0].yaw - fh, -PI, PI)) < 0.01, "조준 해제 뒤 함대 방향 복귀")
	# C. 진형 전환: 슬롯이 바뀌고 새 자리로 수렴한다
	var old_home: Vector3 = v.slots[0].home
	var moved_homes := 0
	var before := []
	for s in v.slots:
		before.append(s.home)
	sq.formation = (v.formation + 1) % 10
	r._reform(v, sq)
	for i in v.slots.size():
		if not v.slots[i].home.is_equal_approx(before[i]):
			moved_homes += 1
	_check(moved_homes > v.slots.size() / 2, "진형 전환 슬롯 이동 %d/%d" % [moved_homes, v.slots.size()])
	var pts := r.formation_points(sq.formation, v.slots.size())
	var idx_ok := true
	for i in v.slots.size():
		idx_ok = idx_ok and v.slots[i].goal.is_equal_approx(Vector3(pts[i].z * r.src.unit_scale(), pts[i].y, -pts[i].x * r.src.unit_scale()))
	_check(idx_ok, "함선 k는 새 진형의 k번 자리(M2)")
	for i in 600:
		r._follow(v, sq, 0.05)
	_check(_max_err(r, v, sq) < 0.02, "진형 전환 후 수렴 err=%.4f" % _max_err(r, v, sq))
	# F. 격침 빈자리: 남은 함선의 슬롯은 그대로이고 빈자리는 메워지지 않는다
	var victim: FleetRenderer.Slot = null
	for s in v.slots:
		if s.alive and not s.flag and s.rank < 0.2:
			victim = s
			break
	_check(victim != null, "앞줄 함선 존재")
	if victim:
		var homes := []
		for s in v.slots:
			homes.append(s.home)
		r._hide_slot(v, victim)
		var kept := true
		for i in v.slots.size():
			kept = kept and v.slots[i].home.is_equal_approx(homes[i])
		_check(kept, "격침 뒤 남은 슬롯 불변")
		_check(not r.has_method("_close_ranks"), "빈자리 메우기 없음")
	# D. 같은 전대 id는 같은 슬롯(결정성)
	var real := r.src.squadron(id)
	var a := r._make_vis(real)
	var b := r._make_vis(real)
	var same := a.slots.size() == b.slots.size()
	for i in a.slots.size():
		same = same and a.slots[i].home.is_equal_approx(b.slots[i].home) and a.slots[i].tau == b.slots[i].tau
	_check(same, "슬롯 결정성")
	a.node.queue_free()
	b.node.queue_free()
	# E. 추종 함수에 난수가 없다
	var text := FileAccess.get_file_as_string("res://view/fleet_render/fleet_renderer.gd")
	var body := text.substr(text.find("func _follow"), text.find("func _make_vis") - text.find("func _follow"))
	_check(not ("sin(clock" in body or "SWAY" in body or "evade" in body), "흔들림·회피 변위 없음")
	_check(not ("randf" in body or "randi" in body or "rng." in body or "randomize" in body), "추종 코드에 난수 없음")
	print("FLEET_FOLLOW_", "PASS" if fails == 0 else "FAIL")
	quit(1 if fails else 0)
