extends SceneTree

# salvo 규칙의 미사일(포격 범주)·함재기 사격 사건이 렌더러 비행 연출이 되는지(표시 전용).
#  1. 사건 → 대기열 → 렌더러가 꺼내 비행체를 만든다 / 2. 미사일은 비행 시간 뒤 사라지고 함재기는 더 오래 남는다
#  3. 다른 범주(line_fire)는 연출을 만들지 않는다 / 4. 실제 전투에서 미사일 명령이 연출로 이어진다

func _initialize() -> void:
	call_deferred("_run")

func _salvo(battle, a, b, cat: String) -> void:
	battle._on_event({"kind": "salvo", "sq": a.id, "other": b.id, "pos": b.pos, "value": {"cat": cat, "n": 6}})

func _run() -> void:
	var battle = (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	battle._restart()
	var r: FleetRenderer = battle.presentation.renderer
	r.update(0.016)
	var a = battle.alive(0)[0]
	var foes: Array = []
	for i in 600:   # 적 함대는 접촉 후에 화면 모델에 생긴다
		battle.sim.step()
		battle._pump()
		foes = battle.fleets.filter(func(f): return f.side == 1 and not f.dead)
		if not foes.is_empty():
			break
	if not TestCheck.ok(self, not foes.is_empty(), "적 함대 접촉"): return
	var b = foes[0]
	battle.salvo_fx.clear()
	r.update(0.016)
	r.weapon_fx.clear()
	_salvo(battle, a, b, "line_fire")
	r.update(0.016)
	if not TestCheck.ok(self, r.weapon_fx.is_empty(), "line_fire는 연출 없음"): return
	_salvo(battle, a, b, "artillery")
	r.update(0.016)
	var nm := r.weapon_fx.filter(func(w): return w.missile).size()
	if not TestCheck.ok(self, nm >= 4 and battle.salvo_fx.is_empty(), "미사일 사건 -> 비행체 %d개, 대기열 비움" % nm): return
	_salvo(battle, a, b, "fighter")
	r.update(0.016)
	if not TestCheck.ok(self, r.weapon_fx.filter(func(w): return not w.missile).size() == 16, "함재기 사건 -> 16기"): return
	for i in 140:   # 2.2초(미사일 최대 0.6 지연 + 1.3 비행)
		r.update(0.016)
	if not TestCheck.ok(self, r.weapon_fx.size() == 16 and r.weapon_fx.all(func(w): return not w.missile), "미사일은 착탄 후 사라지고 함재기는 선회 중"): return
	for i in 120:
		r.update(0.016)
	if not TestCheck.ok(self, r.weapon_fx.is_empty(), "함재기도 소멸"): return
	# 실제 전투: 미사일 사건이 오면 연출 대기열로 들어간다
	battle.selected.assign(battle.alive(0))
	battle.order_move(b.pos)
	var got := false
	for i in 4000:
		battle.sim.step()
		battle._pump()
		if not battle.salvo_fx.is_empty():
			got = battle.salvo_fx.any(func(q): return q.cat == "artillery" or q.cat == "fighter")
			if got:
				break
	if not TestCheck.ok(self, got, "실전투 salvo 사건 -> 연출 대기열"): return
	print("weapon_salvo_fx OK")
	quit(0)
