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
		if s.alive:
			e = maxf(e, s.pos.distance_to(r._target(s, fpos, frot)))
	return e

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 5:
		await process_frame
	var r: FleetRenderer = battle.presentation.renderer
	var core_fingerprint: String = battle.sim.fingerprint()
	var id: int = r.vis.keys()[0]
	var v: FleetRenderer.FleetVis = r.vis[id]
	var sq := {"id": id, "pos": Vector2(1500, 1000), "heading": 0.0, "formation": v.formation}
	# A. 정지 전대에서 모든 함선이 슬롯에 수렴한다
	for i in 400:
		r._follow(v, sq, 0.05)
	_check(_max_err(r, v, sq) < 0.02, "정지 수렴 err=%.4f" % _max_err(r, v, sq))
	# B. 90도 급선회: 바깥쪽 슬롯이 안쪽보다 더 뒤처진다
	sq.heading = PI * 0.5
	for i in 6:
		r._follow(v, sq, 0.05)
	var fpos := r.src.to3(sq.pos)
	var frot := -float(sq.heading) - PI * 0.5
	var rows := []
	for s in v.slots:
		rows.append([Vector2(s.home.x, s.home.z).length(), s.pos.distance_to(r._target(s, fpos, frot))])
	rows.sort_custom(func(a, b): return a[0] < b[0])
	var q := rows.size() / 4
	var inner := 0.0
	var outer := 0.0
	for i in q:
		inner += rows[i][1]
		outer += rows[rows.size() - 1 - i][1]
	_check(outer > inner * 1.5, "선회 지연 바깥 %.2f > 안쪽 %.2f" % [outer / q, inner / q])
	for i in 600:
		r._follow(v, sq, 0.05)
	_check(_max_err(r, v, sq) < 0.02, "선회 후 수렴")
	# 도착 뒤 rest 최적화가 방향 정돈을 중단하면 안 된다.
	var h_fleet := -float(sq.heading) - PI
	var yaw_err := 0.0
	for s in v.slots:
		yaw_err = maxf(yaw_err, absf(angle_difference(s.yaw, h_fleet)))
	_check(yaw_err < 0.003, "정지 후 함수 방향 정돈 %.5f" % yaw_err)
	# 평행 후퇴는 이동 벡터와 반대라도 함수가 뒤집히지 않는다.
	sq["strafe"] = true
	for i in 60:
		sq.pos.y -= 2.0
		r._follow(v, sq, 0.05)
	yaw_err = 0.0
	for s in v.slots:
		yaw_err = maxf(yaw_err, absf(angle_difference(s.yaw, h_fleet)))
	_check(yaw_err < 0.003, "평행 후퇴 함수 방향 유지 %.5f" % yaw_err)
	sq.strafe = false
	for i in 200:
		r._follow(v, sq, 0.05)
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
	_check(moved_homes > v.slots.size() / 2, "진형 전환 슬롯 재배정 %d/%d" % [moved_homes, v.slots.size()])
	for i in 600:
		r._follow(v, sq, 0.05)
	_check(_max_err(r, v, sq) < 0.02, "진형 전환 후 수렴 err=%.4f" % _max_err(r, v, sq))
	# F. 격침 빈자리는 유지한다. 생존 함선이 미확인 자동 전진을 하지 않는다.
	var victim: FleetRenderer.Slot = null
	for s in v.slots:
		if s.alive and not s.flag and s.rank < 0.2:
			victim = s
			break
	_check(victim != null, "앞줄 함선 존재")
	if victim:
		var hole: Vector3 = victim.home
		var survivors := v.slots.filter(func(s): return s.alive and s != victim)
		var survivor_positions := survivors.map(func(s): return s.pos)
		var survivor_homes := survivors.map(func(s): return s.home)
		r._hide_slot(v, victim)
		for i in survivors.size():
			_check(survivors[i].alive and survivors[i].pos == survivor_positions[i] and v.slots.has(survivors[i]), "격침 뒤 생존 함선 정체성·현재위치 보존")
		var refilled := false
		var seen := {}
		var dup := false
		for s in v.slots:
			if not s.alive:
				continue
			refilled = refilled or s.home.is_equal_approx(hole)
			var key := Vector2i(roundi(s.home.x * 100.0), roundi(s.home.z * 100.0))
			dup = dup or seen.has(key)
			seen[key] = true
		_check(not refilled, "격침 빈자리를 자동으로 메우지 않음")
		_check(not dup, "남은 함선 슬롯 중복 없음")
		for i in 600:
			r._follow(v, sq, 0.05)
		for i in survivors.size():
			_check(survivors[i].home == survivor_homes[i] and survivors[i].pos.distance_to(survivor_positions[i]) < 0.02, "격침 뒤 원래 생존 슬롯 유지")
		_check(_max_err(r, v, sq) < 0.02, "격침 후 원래 슬롯 정돈")
	# D. 같은 함대 id는 같은 슬롯·기술 보간(결정성)
	var real := r.src.squadron(id)
	var a := r._make_vis(real)
	var b := r._make_vis(real)
	var same := a.slots.size() == b.slots.size()
	for i in a.slots.size():
		same = same and is_equal_approx(a.slots[i].tau, b.slots[i].tau) and a.slots[i].home == b.slots[i].home
	_check(same, "슬롯·보간 결정성")
	a.node.queue_free()
	b.node.queue_free()
	# E. 추종 함수에 난수가 없다
	var text := FileAccess.get_file_as_string("res://view/fleet_render/fleet_renderer.gd")
	var body := text.substr(text.find("func _follow"), text.find("func _make_vis") - text.find("func _follow"))
	_check(not ("randf" in body or "randi" in body or "rng." in body or "randomize" in body), "추종 코드에 난수 없음")
	_check(battle.sim.fingerprint() == core_fingerprint, "이동·선회·재전환 연출이 코어 지문 불변")
	print("FLEET_FOLLOW_", "PASS" if fails == 0 else "FAIL")
	quit(1 if fails else 0)
