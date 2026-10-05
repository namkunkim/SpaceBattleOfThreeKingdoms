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
		e = maxf(e, s.pos.distance_to(r._target(s, fpos, frot, 0.0)))
	return e

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 5:
		await process_frame
	var r: FleetRenderer = battle.presentation.renderer
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
		rows.append([Vector2(s.home.x, s.home.z).length(), s.pos.distance_to(r._target(s, fpos, frot, 0.0))])
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
	# F. 격침 빈자리: 앞줄 함선이 사라지면 뒤 함선이 그 자리로 올라오고, 남은 함선의 슬롯은 겹치지 않는다
	var victim: FleetRenderer.Slot = null
	for s in v.slots:
		if s.alive and not s.flag and s.rank < 0.2:
			victim = s
			break
	_check(victim != null, "앞줄 함선 존재")
	if victim:
		var hole: Vector3 = victim.home
		r._hide_slot(v, victim)
		r._close_ranks(v, hole)
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
		_check(refilled, "구멍이 메워짐")
		_check(not dup, "남은 함선 슬롯 중복 없음")
		for i in 600:
			r._follow(v, sq, 0.05)
		_check(_max_err(r, v, sq) < 0.02, "메운 뒤 수렴")
	# D. 같은 전대 id는 같은 tau·위상(결정성)
	var real := r.src.squadron(id)
	var a := r._make_vis(real)
	var b := r._make_vis(real)
	var same := a.slots.size() == b.slots.size()
	for i in a.slots.size():
		same = same and is_equal_approx(a.slots[i].tau, b.slots[i].tau) and is_equal_approx(a.slots[i].phase, b.slots[i].phase)
	_check(same, "tau·위상 결정성")
	a.node.queue_free()
	b.node.queue_free()
	# E. 추종 함수에 난수가 없다
	var text := FileAccess.get_file_as_string("res://view/fleet_render/fleet_renderer.gd")
	var body := text.substr(text.find("func _follow"), text.find("func _make_vis") - text.find("func _follow"))
	_check(not ("randf" in body or "randi" in body or "rng." in body or "randomize" in body), "추종 코드에 난수 없음")
	print("FLEET_FOLLOW_", "PASS" if fails == 0 else "FAIL")
	quit(1 if fails else 0)
