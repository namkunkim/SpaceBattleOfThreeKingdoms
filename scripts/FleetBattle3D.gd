extends Node3D
# 실시간 함대 전술 전투 — 전투 노드(호스트).
#
# M1 구조 분리 이후 이 파일은 얇은 접착층이다. 규칙은 core/battle/BattleSim이 계산하고(고정 10Hz 틱),
# 이 노드는 (1) 누산기로 틱을 돌리고 (2) 공개 투영을 화면 모델(view/battle_view_model.gd)에 옮기고
# (3) 코어가 낸 사건을 로그·토스트·연출로 바꾸고 (4) 입력(input/)이 만든 명령을 코어에 넘긴다.
# 상품화 표현 계층(hud/ui_kit, view/fleet_render, input/touch)이 읽는 필드와 함수(fleets, G, selected ...)는
# 화면 모델과 이 노드의 세션 상태로 그대로 제공한다.
#
# 구성: view/(battle_view_3d, camera_rig, fx_layer, battle_view_model) · hud/(battle_hud, fleet_labels, radar)
#       · input/(battle_input, battle_commands) · core/battle/(BattleSim ...)

const WORLD := CameraRig.WORLD
const S := CameraRig.S
const PITCH := CameraRig.PITCH
const MAX_VISIBLE := BattleView3D.MAX_VISIBLE
const FORM_NAMES := ["횡진", "쐐기진", "방진", "종진", "원진", "학익진", "사선진", "어린진", "안행진", "장사진"]
const CMD_R := 560.0
const MISSILE_R := 480.0
const FIGHTER_R := 380.0
const PORTRAIT_SHEET := "res://assets/portraits/commanders_sheet_v1.png"
var ALLY_DEF: Array = PocSetup.profile().ally
var FOE_DEF: Array = PocSetup.profile().foe
var REINF_DEF: Array = PocSetup.profile().reinf
const CMDS := [
	{"id": "stop", "key": "S", "name": "정지", "cost": 0},
	{"id": "def", "key": "D", "name": "방어진형", "cost": 0},
	{"id": "missile", "key": "M", "name": "미사일 일제사격", "cost": 2},
	{"id": "fighter", "key": "F", "name": "함재기 발진", "cost": 3},
	{"id": "charge", "key": "C", "name": "전 함대 돌격", "cost": 3},
	{"id": "rally", "key": "R", "name": "기함으로 집결", "cost": 0},
	{"id": "retreat", "key": "G", "name": "후퇴", "cost": 0},
	{"id": "all", "key": "A", "name": "전 함대 선택", "cost": 0},
]
const SAY := {
	"stop": "전 함 정지.", "def_on": "방어진형으로 전환!", "def_off": "방어진형 해제.", "missile": "미사일, 일제 발사!",
	"fighter": "함재기, 발진!", "charge": "전 함대, 돌격하라!", "rally": "기함 주위로 집결한다.", "retreat": "전선을 물린다. 후퇴!",
	"move_all": "전 함대 전진!", "move": "항로 변경, 전진.", "ai_def": "방어진을 펴라!", "ai_missile": "미사일 발사!", "ai_fighter": "전투정 발진!",
}
const REJECT := {
	"cp_charge": "커맨드 포인트가 부족합니다 (필요 3)", "cp_missile": "커맨드 포인트가 부족합니다 (필요 2)", "cp_fighter": "커맨드 포인트가 부족합니다 (필요 3)",
	"missile_no_target": "미사일 사정거리 안에 적이 없습니다", "missile_reload": "미사일 재장전 중",
	"fighter_no_target": "함재기 작전 반경 안에 적이 없습니다", "fighter_reload": "함재기 정비 중",
	"no_selection": "먼저 아군 함대를 선택하세요",
}
const END_TEXT := {
	"flagship_lost": "기함이 격침되었습니다. 지휘 계통이 무너진 함대는 회랑에서 철수합니다.",
	"annihilation": "위 원정군이 회랑에서 모두 사라졌습니다. 회랑은 연합의 손에 남습니다.",
}

# 표현 계층(view/fleet_render, hud/ui_kit)이 교신·알림을 받는 통로. kind: "", "foe", "sys", "toast"
signal battle_event(kind: String, text: String, fleet_id: int)
const PRESENTATION := "res://hud/ui_kit/presentation.gd"
var presentation: Node = null

# ---- 코어와 시간 ----
var sim: BattleSim
var clock := TickClock.new()
var battle_seed := 0
var _sim_acc_clock := TickClock.new()   # update_sim(dt)용(속도 ×1 고정)

# ---- 화면 모델과 표현 ----
var vm := BattleViewModel.new()
var rig := CameraRig.new()
var view3d := BattleView3D.new()
var fx: FxLayer
var ui: FleetLabels
var radar: BattleRadar
var hud := BattleHud.new()
var cmds: BattleCommands
var input_node: BattleInput
var fleets: Array[BattleViewModel.FleetView] = vm.fleets
var missiles: Array[BattleViewModel.MissileView] = vm.missiles
var swarms: Array[BattleViewModel.SwarmView] = vm.swarms
var floats: Array:
	get: return fx.floats

# ---- 세션 상태(선택·그룹·끌기 같은 UI 상태) ----
var G := {}
var selected: Array = []
var inspect = null
var groups := {}
var marker := {}
var drag := {}
var now_t := 0.0
var vsize := Vector2(1600.0, 900.0)
var sheet: Texture2D
var cam_pos: Vector2:
	get: return rig.cam_pos
	set(v): rig.cam_pos = v
var cam_z: float:
	get: return rig.cam_z
	set(v): rig.cam_z = v
var camera: Camera3D:
	get: return rig.camera
var _ptex := {}

func _ready() -> void:
	randomize()
	vsize = get_viewport().get_visible_rect().size
	rig.vsize = vsize
	sheet = load(PORTRAIT_SHEET) as Texture2D
	view3d.setup(self, rig)
	_build_canvas()
	cmds = BattleCommands.new(self)
	input_node = BattleInput.new()
	input_node.name = "BattleInput"
	add_child(input_node)
	input_node.setup(self, cmds)
	init_game()
	# 상품화 표현 계층이 있으면 POC 3D 함대와 HUD를 대신한다.
	if ResourceLoader.exists(PRESENTATION):
		presentation = load(PRESENTATION).new()
		add_child(presentation)
		presentation.setup(self)

func _build_canvas() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	fx = FxLayer.new()
	canvas.add_child(fx)
	fx.setup(rig, vm)
	ui = FleetLabels.new()
	canvas.add_child(ui)
	ui.setup(self)
	radar = BattleRadar.new()
	radar.setup(self)
	hud.build(self, ui, vsize, radar)

# ============================================================ 시작·종료 흐름
func init_game() -> void:
	for f in fleets:
		view3d.free_fleet(f)
	vm.reset()
	fx.clear()
	battle_seed = randi()
	sim = BattleSim.new(battle_seed)
	clock = TickClock.new()
	_sim_acc_clock = TickClock.new()
	selected.clear()
	inspect = null
	marker = {}
	drag = {}
	G = {"t": 0.0, "cp": 3.0, "ecp": 3.0, "reinf": false, "state": "brief", "speed": 1, "killed": 0.0, "lost": 0.0, "panel_t": 0.0, "over": false, "end_t": -1.0, "end_win": false, "end_text": ""}
	sim.drain_events()
	_sync()
	groups = {1: [fleets[0].id], 2: [fleets[1].id, fleets[3].id], 3: [fleets[2].id, fleets[4].id], 4: [fleets[5].id]}
	rig.cam_pos = Vector2(900.0, 1150.0)
	rig.cam_z = clampf(vsize.x / 1500.0, 0.45, 1.0)
	hud.reset()
	refresh_panel()

func _start() -> void:
	hud.brief_ov.visible = false
	hud.end_ov.visible = false
	hud.menu_ov.visible = false
	G.state = "play"
	selected.assign([flag(0)])
	refresh_panel()
	add_log("전 함대, 전투 배치 완료.", "", fleets[0])
	var foe = null
	for f in fleets:
		if f.side == 1 and not f.is_flag:
			foe = f
			break
	get_tree().create_timer(0.9).timeout.connect(func(): if G.state == "play": add_log("위군 선봉, 회랑 진입 확인.", "foe", foe))

func _restart() -> void:
	init_game()
	_start()

func _quit() -> void:
	get_tree().quit()

func _toggle_menu() -> void:
	if G.state == "play":
		G.state = "pause"
		hud.menu_ov.visible = true
	elif G.state == "pause":
		_close_menu()

func _close_menu() -> void:
	hud.menu_ov.visible = false
	G.state = "play"

func _toggle_speed() -> void:
	G.speed = 2 if G.speed == 1 else 1
	hud.speed_btn.text = "×%d" % G.speed

func end_game(win: bool, text: String) -> void:
	G.over = true
	G.end_t = 1.6
	G.end_win = win
	G.end_text = text

func _show_end() -> void:
	G.state = "end"
	hud.show_end(G.end_win, G.end_text, G.killed, G.lost, G.t)

# ============================================================ 시간
func _process(delta: float) -> void:
	now_t += delta
	var dt := minf(0.05, delta)
	if G.state == "play":
		input_node.poll_camera(dt)
		clock.set_speed(float(G.speed))
		var n := clock.advance(delta)
		for i in n:
			if sim.st.over:
				break
			sim.step()
		vm.alpha = clock.alpha()
		_pump()
		vm.interpolate(clock.alpha())
		_tick_view(dt * G.speed)
		G.panel_t -= dt
		if G.panel_t <= 0.0:
			G.panel_t = 0.25
			refresh_panel()
		if G.over and G.end_t > 0.0:
			G.end_t -= dt
			if G.end_t <= 0.0:
				_show_end()
	elif G.state == "brief":
		rig.cam_pos.x = 900.0 + sin(now_t / 5.0) * 120.0
	rig.update()
	view3d.sync(fleets)
	hud.paint_cmds()
	fx.queue_redraw()
	ui.queue_redraw()
	radar.queue_redraw()

# 화면 쪽 시간 진행(말풍선, 표식, 연출). dt는 게임 속도를 반영한 시간이다.
func _tick_view(dt: float) -> void:
	for f in fleets:
		if f.speech_t > 0.0:
			f.speech_t -= dt
	if not marker.is_empty():
		marker.t -= dt
		if marker.t <= 0.0:
			marker = {}
	fx.update(dt)

# 호환: 프레임 폭(dt초)만큼 게임을 진행한다. 헤드리스 테스트가 쓴다(속도 ×1, 상태 무관).
func update_sim(dt: float) -> void:
	var n := _sim_acc_clock.advance(dt)
	for i in n:
		if sim.st.over:
			break
		sim.step()
	_pump()
	vm.interpolate(1.0)
	_tick_view(dt)
	if G.over and G.end_t > 0.0 and G.state == "play":
		G.end_t -= dt
		if G.end_t <= 0.0:
			_show_end()

# ============================================================ 코어 ↔ 화면
# 투영을 화면 모델에 반영하고 새 전대의 3D 노드를 만든다.
func _sync() -> void:
	var fresh := vm.apply(sim.projection(0))
	for f in fresh:
		view3d.build_fleet(f)
	G.t = vm.clock_s
	G.cp = vm.cp
	G.reinf = vm.reinf
	G.killed = vm.killed
	G.lost = vm.lost
	view3d.sync(fleets)

# 사건을 모두 처리하고 화면 모델을 맞춘다.
func _pump() -> void:
	_sync()
	for e in sim.drain_events_for(0):
		_on_event(e)

# 플레이어 명령(input/ 이 만든 사전)을 코어에 넘긴다. 즉시 적용되고 명령 기록에 남는다.
func issue(cmd: Dictionary) -> void:
	sim.issue(BattleSim.command(0, cmd.ids, cmd.kind, cmd.get("target_id", -1), cmd.get("point", Vector2.ZERO), cmd.get("args", {})))
	_pump()

# 명령 되돌리기(U2): 스냅숏 {id: [has_move, move_to, target_id, defense]}의 상태로 돌아가는 새 명령을 발행한다.
func restore_orders(snap: Dictionary) -> void:
	var ids := []
	for id in snap:
		ids.append(int(id))
	issue({"kind": "restore", "ids": ids, "args": {"orders": snap}})

func _on_event(e: Dictionary) -> void:
	var f = vm.fleet(e.sq) if e.sq >= 0 else null
	match e.kind:
		"say":
			if f:
				var txt: String = SAY.get(e.value, "")
				if e.value == "attack":
					var t = vm.fleet(e.other)
					txt = "%s 함대를 친다!" % t.fname if t else ""
				if txt != "":
					f.speech = txt
					f.speech_t = 2.4
		"volley":
			add_log("%d개 함대 미사일 일제사격" % e.value, "", f)
		"charge":
			add_log("돌격 명령 · 10초간 화력·속도 상승", "", f)
		"rejected":
			if e.other == 0:
				toast(REJECT.get(e.value, "명령을 수행할 수 없습니다"))
		"reinforcements":
			add_log("경고: 위군 별동대 2개 함대가 측면에 출현!", "sys", null)
			toast("적 증원 함대 출현 · 측면 주의")
		"level_up":
			fx.float_text(e.pos + Vector2(0.0, -60.0), "LEVEL UP", BattleHud.C_GOLD)
		"flank":
			var att = vm.fleet(e.sq)
			fx.float_text(e.pos + Vector2(0.0, -50.0), "배후 공격!" if e.value > 1.4 else "측면 공격!", BattleHud.C_FOE if (att and att.side == 1) else BattleHud.C_GOLD)
		"ship_lost":
			if f:
				fx.on_ship_lost(f, e.value)
		"missile_hit":
			if f:
				fx.on_missile_hit(e.pos, f.side)
		"destroyed":
			if f:
				fx.on_destroyed(f)
				selected.erase(f)
				if inspect == f:
					inspect = null
				var src = vm.fleet(e.other) if e.other >= 0 else null
				if f.side == 1:
					add_log("%s 함대 격파!" % f.fname, "", src if (src and src.side == 0) else null)
					if src and not src.dead and src.side == 0:
						src.speech = "적 함대 격파!"
						src.speech_t = 2.4
				else:
					add_log("%s 함대가 궤멸되었습니다" % f.fname, "foe", f)
				refresh_panel()
		"battle_end":
			end_game(vm.outcome.win, END_TEXT.get(e.value, ""))

# ============================================================ 화면 도우미
func w3(p: Vector2, y: float = 0.0) -> Vector3:
	return rig.w3(p, y)

func w2s(p: Vector2) -> Vector2:
	return rig.w2s(p)

func s2w(sp: Vector2) -> Vector2:
	return rig.s2w(sp)

func _clamp_cam() -> void:
	rig.clamp_cam()

func _zoom(mp: Vector2, factor: float) -> void:
	rig.zoom(mp, factor)

func label_rect(f) -> Rect2:
	return ui.label_rect(f)

func _portrait_tex(i: int) -> Texture2D:
	if _ptex.has(i):
		return _ptex[i]
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2((i % 3) * 512.0 + 5.0, (i / 3) * 512.0 + 5.0, 502.0, 502.0)
	_ptex[i] = at
	return at

func toast(text: String) -> void:
	battle_event.emit("toast", text, -1)
	hud.toast(text)

func add_log(text: String, kind: String, f) -> void:
	battle_event.emit(kind, text, f.id if f else -1)
	hud.add_log(text, kind, f)

func refresh_panel() -> void:
	hud.refresh_panel()

# ============================================================ 조회(호환)
func alive(side: int) -> Array[BattleViewModel.FleetView]:
	return vm.alive(side)

func flag(side: int):
	return vm.flag(side)

func by_id(id: int):
	return vm.fleet(id)

func nearest_foe(f, max_r: float):
	return vm.nearest_foe(f, max_r)

func my_sel() -> Array:
	var out: Array = []
	for f in selected:
		if not f.dead:
			out.append(f)
	return out

func flank_mul(att, tgt) -> float:
	return sim.rs.flank_mul(att.pos, tgt.pos, tgt.heading)

func power(f) -> float:
	return sim.rs.power(f.lv, f.charge_t > 0.0, f.in_cmd, f.defense)

# ============================================================ 입력(호환: input/ 으로 넘긴다)
func do_cmd(id: String) -> void:
	cmds.do_cmd(id)

func order_move(w: Vector2) -> void:
	cmds.order_move(w)

func order_attack(t) -> void:
	cmds.order_attack(t)

func _hit_fleet(sp: Vector2):
	return input_node.hit_fleet(sp)

func _click_at(sp: Vector2, btn: int, shift: bool) -> void:
	input_node.click_at(sp, btn, shift)

func _group_down(n: int) -> void:
	input_node.group_down(n)

func _group_up(n: int) -> void:
	input_node.group_up(n)

func group_fleets(n: int) -> Array:
	return input_node.group_fleets(n)

func same_sel(g: Array) -> bool:
	return input_node.same_sel(g)

func select_group(n: int) -> void:
	input_node.select_group(n)

func assign_group(n: int) -> void:
	input_node.assign_group(n)

# ============================================================ 테스트 훅(규칙 단위 테스트가 상태를 직접 만든다)
func apply_dmg(src, tgt, amt: float) -> void:
	sim.debug_damage(src.id if src else -1, tgt.id, amt * BattleRules.MILLI)
	_pump()

func fire_missiles(f, tgt) -> void:
	sim.debug_fire_missiles(f.id, tgt.id)
	_pump()

func launch_fighters(f, tgt) -> void:
	sim.debug_launch_fighters(f.id, tgt.id)
	_pump()

func spawn_reinf() -> void:
	sim.debug_spawn_reinf()
	_pump()
