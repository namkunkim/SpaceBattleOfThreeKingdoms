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
var profile_def := "res://data/profiles/red_cliffs_rt.json"   # 적벽 시나리오 프로필. ""이면 POC 프로필(규칙 문구 대조 테스트 전용)
var difficulty := "표준"
var profile_patch := Callable()   # 측정 전용(bench_density 1,500척 프리셋): 프로필을 받아 고친다. 게임 흐름에서는 비어 있다
var move_mul := 150.0   # 이동 배율: 화면 한 폭(1600)을 약 10초에 건넌다. 헤드리스 테스트는 1로 둔다
var turn_mul := 15.0    # 선회율 배율: 선회 반경(속도÷선회율)이 도착 판정(settle 0.7×속도) 안에 들어야 목적지를 돌지 않는다. 조건은 선회율 > 82°/초(속도와 무관)
const FIELD_SIZE := CameraRig.WORLD * 0.5   # 전투 전장 크기: 배경판(3400×2300)의 가로·세로 1/2 = 1700×1150 (이전 6800×4600의 1/4)
var ALLY_DEF: Array = []   # 브리핑·결산 편성표: 시나리오 프로필의 아군(유비군+손권군) 전대
var FOE_DEF: Array = []    # 브리핑 적 정보: 처음부터 배치되는 적 전대만(증원 전대는 안개 속, 규모를 미리 알리지 않는다)
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
	"flagship_lost": "기함이 격침되었습니다. 지휘 계통이 무너진 함대는 적벽에서 철수합니다.",
	"annihilation": "조조군이 적벽에서 모두 사라졌습니다. 적벽의 궤도는 연합의 손에 남습니다.",
}

# 표현 계층(view/fleet_render, hud/ui_kit)이 교신·알림을 받는 통로. kind: "", "foe", "sys", "toast"
signal battle_event(kind: String, text: String, fleet_id: int)
signal sfx_event(name: String)   # 코어 사건 → 효과음 이름(UiSound 사건)
signal sfx_loop(name: String, level: float)   # 코어 사건 → 루프 효과음(UiSound.set_loop). M9 화공 fire_loop
const PRESENTATION := "res://hud/ui_kit/presentation.gd"
var presentation: Node = null
var hud_hidden := false   # F1 녹화용: HUD만 숨긴다(3D·VFX·진행은 그대로)
var _saved_title := ""

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
var multi := false   # 다중 선택 모드(터치): 탭 = 추가/해제, 빈 곳 끌기 = 범위 선택
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
	# 천하 지도에서 들어온 전투면 BattleBrief의 시드를 쓴다(같은 Brief = 같은 전투, WORLD-MAP-LINK §3).
	var link := get_node_or_null("/root/WorldLink")
	battle_seed = link.brief.seed if link and link.routed() else randi()
	var profile := ScenarioProfile.load_profile(profile_def, difficulty) if profile_def != "" else PocSetup.profile()
	if profile_def != "" and not profile.is_empty():
		ScenarioProfile.enlarge_field(profile, FIELD_SIZE)   # 전장을 FIELD_SIZE로 맞추고 배치를 비율대로 늘린다. 미니맵은 이 전장을 비례 축소해 보여 준다
	if profile_def != "" and not profile.is_empty():
		rig.margin = 0.4   # 시작 배율에서도 두 손가락으로 화면을 옮길 수 있게
		GameSettings.slow_mode = GameSettings.SLOW_OFF   # 선택 감속 끔(저장 설정은 건드리지 않는다)
		ScenarioProfile.tune_for_play(profile, move_mul, turn_mul)
	if profile_patch.is_valid() and not profile.is_empty():
		profile_patch.call(profile)
	sim = BattleSim.new(battle_seed, BattleRules.TICK_HZ, profile)
	ALLY_DEF = profile.ally.map(_with_portrait)
	FOE_DEF = profile.foe.filter(func(d): return int(d.wait) == 0).map(_with_portrait)
	clock = TickClock.new()
	_sim_acc_clock = TickClock.new()
	selected.clear()
	multi = false
	inspect = null
	marker = {}
	drag = {}
	G = {"t": 0.0, "cp": 3.0, "ecp": 3.0, "reinf": false, "state": "brief", "speed": 1, "slow": 1.0, "killed": 0.0, "lost": 0.0, "panel_t": 0.0, "over": false, "end_t": -1.0, "end_win": false, "end_text": ""}
	sim.drain_events()
	_sync()
	_assign_default_groups()
	rig.limit = sim.rs.world
	view3d.build_backdrop()
	rig.cam_pos = _field_center()
	_brief_x = rig.cam_pos.x
	var mine := alive(0)
	if profile_def != "" and not mine.is_empty():   # 시작 화면은 아군(서쪽 끝) 쪽. 전장 밖으로는 clamp_cam이 막는다
		var c := Vector2.ZERO
		for f in mine:
			c += f.pos
		rig.cam_pos = c / mine.size()
		_brief_x = rig.cam_pos.x
	rig.cam_z = clampf(vsize.x / (sim.rs.world.x + 100.0), 0.45, 1.0)   # 전장 폭이 화면에 들어오게
	if profile_def != "":
		rig.cam_z = 0.9   # 전장이 커서 전체를 담으면 함대가 작다. 시작은 함대가 읽히는 배율, 확대·축소는 두 손가락
	hud.reset()
	refresh_panel()

# 프로필 전장 크기와 중심. 시나리오 좌표는 (0,0)에서 시작한다.
func field() -> Vector2:
	return rig.limit

var _brief_x := 0.0   # 브리핑 배경 카메라가 흔들리는 중심 x(시작 화면 위치)

func _field_center() -> Vector2:
	return rig.limit * 0.5

# 프로필 전대 정의의 초상 번호(p)는 0 고정이라 인물 ID로 초상 시트 번호를 채운다. 없는 인물은 0.
func _with_portrait(d: Dictionary) -> Dictionary:
	var e := d.duplicate()
	e.p = maxi(0, int(Commanders.PORTRAIT.get(d.get("commander_id", ""), d.get("p", 0))))
	return e

# 기본 그룹 1~n: 아군 시나리오 함대(fleet_groups) 하나가 번호 하나다(등장 순서). 코어 상태가 아닌 UI 편성이다.
func _assign_default_groups() -> void:
	groups = {}
	var num := {}
	for f in fleets:
		if f.side != 0:
			continue
		if not num.has(f.group_id):
			num[f.group_id] = num.size() + 1
			groups[num[f.group_id]] = []
		groups[num[f.group_id]].append(f.id)

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
	get_tree().create_timer(0.9).timeout.connect(func(): if G.state == "play": add_log("조조군 선봉, 적벽 진입 확인.", "foe", foe))

func _restart() -> void:
	init_game()
	_start()

func _quit() -> void:
	get_tree().quit()

# 천하 지도에서 들어온 전투인가(결과 화면의 "천하로", 시작 화면 생략)
func routed() -> bool:
	var link := get_node_or_null("/root/WorldLink")
	return link != null and link.routed()

# 천하 지도로 돌아간다. 전투가 끝났으면 결과(BattleOutcome)를, 아니면 결과 없이.
func back_to_world() -> void:
	var link := get_node_or_null("/root/WorldLink")
	if link == null:
		return
	link.back_to_world(BattleOutcome.from_sim(sim, link.brief) if sim.st.over else null)

func _toggle_menu() -> void:
	if G.state == "play":
		G.state = "pause"
		hud.menu_ov.visible = true
	elif G.state == "pause":
		_close_menu()

func _close_menu() -> void:
	hud.menu_ov.visible = false
	G.state = "play"

# 영상 촬영용 HUD 숨김(LEGAL-YOUTUBE-RISK §3-①-B). 창 제목도 중립으로 바꿔 게임 이름이 잡히지 않게 한다.
func toggle_hud() -> void:
	hud_hidden = not hud_hidden
	if presentation and presentation.hud:
		presentation.hud.get_parent().visible = not hud_hidden
	else:
		ui.visible = not hud_hidden
	var win := get_window()
	if hud_hidden:
		_saved_title = win.title
		win.title = "Capture"
	else:
		win.title = _saved_title

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
		clock.set_speed(float(G.speed) * G.slow)
		var n := clock.advance(delta)
		for i in n:
			if sim.st.over:
				break
			if i > 0 and i == n - 1:
				_sync()   # 한 프레임에 여러 틱이면 마지막 틱 직전 상태를 보간 시작점(ppos)으로 둔다. 안 하면 2틱 구간을 1틱 alpha로 보간해 배속에서 표시가 앞뒤로 튄다
			sim.step()
		var a := 1.0 if sim.st.over else clock.alpha()   # 전투가 끝나면 틱이 멈춘다: 보간을 마지막 위치에 고정(안 하면 결과 화면까지 직전 틱과 사이를 반복 재생해 흔들린다)
		vm.alpha = a
		if n > 0:   # 틱이 없으면 투영·사건이 그대로다(명령·디버그 경로는 직접 _pump한다). 매 프레임 투영을 다시 만들면 1,500척에서 약 3ms
			_pump()
		vm.interpolate(a)
		_tick_view(dt * G.speed * G.slow)
		G.panel_t -= dt
		if G.panel_t <= 0.0:
			G.panel_t = 0.25
			refresh_panel()
		if G.over and G.end_t > 0.0:
			G.end_t -= dt
			if G.end_t <= 0.0:
				_show_end()
	elif G.state == "brief" and not GameSettings.reduce_motion:
		# 타이틀·서막·브리핑 뒤 전장이 천천히 흐른다. 동작 줄이기면 멈춘다.
		rig.cam_pos.x = _brief_x + sin(now_t / 5.0) * 120.0
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

# 코어 사건 → 효과음. 코어에 아직 없는 사건: 함재기 기관포·회수, 보호막·장갑 피격
const SFX_OF := {"missile_launch": "missile_launch", "missile_hit": "missile_hit", "fighter_launch": "fighter_launch", "charge": "engine_boost",
	"chain_explosion": "chain_explosion", "fire_ignite": "fire_ignite"}   # M9 화공: 발동 폭발, 불붙음(번짐 포함)
const SFX_OF_CAT := {"artillery": "laser_heavy", "line_fire": "laser_light"}

func _on_event(e: Dictionary) -> void:
	var f = vm.fleet(e.sq) if e.sq >= 0 else null
	if SFX_OF.has(e.kind):
		sfx_event.emit(SFX_OF[e.kind])
	elif e.kind == "salvo" and SFX_OF_CAT.has(e.value.cat):
		sfx_event.emit(SFX_OF_CAT[e.value.cat])
	elif e.kind == "fire_loop":
		sfx_loop.emit("fire_loop", 1.0 if e.value.on else 0.0)   # 불이 타는 동안(발동 ~ 번짐 끝)
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

func order_move(w: Vector2, strafe := false, facing_deg = null) -> void:
	cmds.order_move(w, strafe, facing_deg)

func order_face(rad: float) -> void:
	cmds.order_face(rad)

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
