extends SceneTree

# 실행: Godot --path . --script tools/scenario/cross_counter_drill.gd
# 검증: Godot --headless --path . --script tools/scenario/cross_counter_drill.gd -- --verify
const CONFIG := "res://data/scenarios/cross_counter_drill.json"
var cfg: Dictionary
var battle: Node
var phase := 0
var banner: Label
var finished := false
var active_sim: BattleSim

func _initialize() -> void:
	call_deferred("_run")

func _patch(p: Dictionary) -> void:
	p.profile_id = cfg.scenario_id
	var a: Dictionary = p.ally[0].duplicate(true)
	var b: Dictionary = p.foe[0].duplicate(true)
	var defs := [a, b]
	for i in 2:
		var d: Dictionary = defs[i]
		var spec: Dictionary = cfg.fleets[i]
		d.name = spec.name
		d.role = spec.role
		d.faction_id = "sun_quan" if i == 0 else "cao_cao"
		d.x = spec.position[0]
		d.y = spec.position[1]
		d.flag = true
		d.wait = 0
		d.formation_id = "FRM-01"
		d.composition = cfg.composition.duplicate(true)
		d.ships = 0
		for entry in d.composition:
			d.ships += int(entry.count)
		d.command = 100
		d.might = 80
		d.intellect = 80
		d.start_morale_bp = 10000
		d.erase("morale_group")
		d.erase("fill_bp")
	p.ally = [a]
	p.foe = [b]
	p.reinf = []
	p.erase("ai")
	# 모의전은 사격·이동만 사용한다. 적벽의 화공·질병·탈출·결정 카드는 개입하지 않는다.
	p.scenario = {}
	# UI가 사기·돌격 설명을 읽으므로 규칙 사전은 남기고, 빈 scenario로 해당 모듈을 끈다.
	for key in ["terrain", "supply", "detection"]:
		p.combat.erase(key)
	p.combat.period_s = cfg.period_s

func _prepare(sim: BattleSim) -> void:
	sim.st.seed_id = int(cfg.seed)
	sim.rng = BattleRng.new("%s|%d" % [sim.profile_id, int(cfg.seed)])
	sim.st.ai_timer = 1 << 50
	for i in 2:
		var f: FleetState = sim.st.fleets[i]
		f.heading = deg_to_rad(float(cfg.fleets[i].heading_deg))
		var dst: Array = cfg.fleets[i].destination
		sim.issue(BattleSim.command(i, [f.id], "move", -1, Vector2(dst[0], dst[1])))

func _advance(sim: BattleSim) -> void:
	if phase == 0 and sim.st.fleets[0].pos.x > sim.st.fleets[1].pos.x + 180.0:
		phase = 1
		# 서로의 옆을 지난 다음 반전. 양측 모두 실제 공격 명령을 사용한다.
		for i in 2:
			sim.issue(BattleSim.command(i, [sim.st.fleets[i].id], "attack", sim.st.fleets[1 - i].id))
		if banner:
			banner.text = "② 크로스 카운터 — 양 함대 반전 · 재교전"

func _run() -> void:
	cfg = ProfileLoader.read_json(CONFIG)
	if "--verify" in OS.get_cmdline_user_args():
		_verify()
		return
	battle = (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	battle.move_mul = float(cfg.move_mul)
	battle.turn_mul = float(cfg.turn_mul)
	battle.profile_patch = _patch
	root.add_child(battle)
	battle.set_process(false)
	await process_frame
	battle.presentation.hud.guard.enabled = false
	battle.presentation.hud.begin_battle()
	# begin_battle가 편성을 다시 만들 수 있으므로 시작 직후에 경로를 설정한다.
	_prepare(battle.sim)
	active_sim = battle.sim
	battle.rig.cam_pos = Vector2(850, 575)
	battle.rig.cam_z = 0.65
	var layer := CanvasLayer.new()
	layer.layer = 120
	root.add_child(layer)
	banner = Label.new()
	banner.position = Vector2(450, 65)
	banner.add_theme_font_size_override("font_size", 24)
	banner.add_theme_color_override("font_color", Color(1.0, 0.87, 0.5))
	banner.add_theme_color_override("font_shadow_color", Color.BLACK)
	banner.add_theme_constant_override("shadow_outline_size", 6)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.text = "① 교차 접근 — 양측 60척 · 자동 기동 / Space 일시정지"
	layer.add_child(banner)
	battle.set_process(true)
	process_frame.connect(_observe)
	if "--capture" in OS.get_cmdline_user_args():
		_capture()

func _capture() -> void:
	battle.set_process(false)
	for tick in 200:
		_advance(battle.sim)
		battle.update_sim(0.1)
		await process_frame
	for frame in 4:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("res://out/cross-counter-preview.png")
	print("CROSS_COUNTER_CAPTURE_DONE")
	quit()

func _observe() -> void:
	if active_sim != battle.sim:
		active_sim = battle.sim
		phase = 0
		finished = false
		_prepare(active_sim)
		banner.text = "① 교차 접근 — 양측 60척 · 자동 기동 / Space 일시정지"
	if finished:
		return
	_advance(battle.sim)
	if battle.G.over or battle.G.t >= float(cfg.duration_s):
		finished = true
		battle.G.state = "pause"
		banner.text = "③ 모의전 종료 — 연합 손실 %d척 / 조조 손실 %d척 · 창을 닫으면 종료" % [battle.sim.st.fleets[0].lost_ships, battle.sim.st.fleets[1].lost_ships]

func _verify() -> void:
	var p := ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json")
	ScenarioProfile.enlarge_field(p, Vector2(1700, 1150))
	ScenarioProfile.tune_for_play(p, float(cfg.move_mul), float(cfg.turn_mul))
	_patch(p)
	var sim := BattleSim.new(int(cfg.seed), BattleRules.TICK_HZ, p)
	_prepare(sim)
	var volleys := [0, 0]
	var return_volleys := [0, 0]
	var rejected := []
	for tick in int(float(cfg.duration_s) * BattleRules.TICK_HZ):
		_advance(sim)
		sim.step()
		for e in sim.drain_events():
			if e.kind == "salvo":
				var side: int = sim.st.fleets[0].side if e.sq == sim.st.fleets[0].id else sim.st.fleets[1].side
				volleys[side] += 1
				if phase == 1:
					return_volleys[side] += 1
			if e.kind == "rejected":
				rejected.append(e.value)
	var ok: bool = phase == 1 and volleys[0] > 0 and volleys[1] > 0 and return_volleys[0] > 0 and return_volleys[1] > 0 and rejected.is_empty()
	print("CROSS_COUNTER_VERIFY ok=", ok, " crossed=", phase == 1, " volleys=", volleys, " counter_volleys=", return_volleys, " rejected=", rejected)
	sim.salvo.sim = null
	quit(0 if ok else 1)
