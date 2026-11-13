extends SceneTree

# 천하 지도 ↔ 전장 연동 검증(헤드리스, docs/battle-core/WORLD-MAP-LINK.md §6).
# 1 데이터 스냅숏 2 계약 직렬화 3 결산 규칙 4 결정성(같은 Brief = 같은 결과, 스레드·직접 실행 동일)
# 5 화면: 터치 탭·두 손가락 확대, 카드, 터치 크기(태블릿 48dp) 6 왕복: 천하 → 출격 → 전장 → 결과 → 천하
# 실행: godot --headless --path . -s tests/world_link.gd   (결정성까지 1~2분. --quick이면 4를 건너뛴다)

var fails := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		push_error("TEST_FAIL " + msg)

func _frames(n := 4) -> void:
	for i in n:
		await process_frame

func _seconds(s: float) -> void:
	await create_timer(s).timeout

func _run() -> void:
	_data()
	_contracts()
	_rules()
	if not OS.get_cmdline_user_args().has("--quick"):
		await _determinism()
	await _legacy_screen()
	await _development_sortie()
	await _round_trip()
	await _prepare_failure_return()
	if fails == 0:
		print("WORLD_LINK_PASS")
		quit(0)
	else:
		print("WORLD_LINK_FAIL %d" % fails)
		quit(1)

# ------------------------------------------------------------ 1 데이터
func _data() -> void:
	var w := WorldMapScreen.read_world()
	_check(not w.is_empty(), "world_208.json 읽기")
	_check(w.systems.size() == 19 and w.regions.size() == 4 and w.bodies.size() == 7, "19성계·형주 4권역·구지 행성계 7천체")
	_check(int(w.source.map_version) == 3, "본편 지도 v3")
	var ids := []
	for b in w.bodies:
		ids.append(b.id)
	_check(ids.has(w.focus.body), "앵커 천체(구지)")
	for k in BattleOutcome.KINDS:
		_check(w.outcome_owners.has(k) and (w.outcome_owners[k] as Dictionary).size() == 4, "결과 권역 소유 " + k)
	_check(w.edge_labels.get("cao_exit", "") != "" and w.edge_labels.get("alliance_exit", "") != "", "방위 표식")

# ------------------------------------------------------------ 2 계약
func _contracts() -> void:
	var b := BattleBrief.new()
	b.seed = 4242
	b.difficulty = "상급"
	b.mode = "auto"
	b.edge_labels = {"cao_exit": "장강 대항로"}
	var b2 := BattleBrief.from_dict(JSON.parse_string(JSON.stringify(b.to_dict())))
	_check(b2.to_dict() == b.to_dict(), "Brief JSON 왕복")
	_check(b.validate() == "", "Brief 유효")
	b2.mode = "x"
	_check(b2.validate() != "", "지휘 방식 검사")
	b2.mode = "auto"
	b2.whatif_cards = ["southeast_wind"]
	_check(b2.validate() != "", "what-if는 M9 전에 거부")
	_check(not b.profile().is_empty(), "Brief → 적벽 프로필")
	var o := BattleOutcome.new()
	o.kind = "alliance_win"
	o.win = true
	o.reason = "cao_morale_collapse"
	o.grade = "우세"
	o.cao_status = "severe"
	o.t_s = 734.5
	o.loss_pct = {"alliance": 21, "foe": 58}
	o.ending = "J-D4"
	o.line = "E6"
	o.seed = 7
	var o2 := BattleOutcome.from_dict(JSON.parse_string(JSON.stringify(o.to_dict())))
	_check(o2.to_dict() == o.to_dict(), "Outcome JSON 왕복")

# ------------------------------------------------------------ 3 결산 규칙
func _rules() -> void:
	_check(BattleOutcome.grade_of(true, 6000) == "결정적 승리" and BattleOutcome.grade_of(true, 5999) == "우세", "등급 60 경계")
	_check(BattleOutcome.grade_of(true, 1000) == "근소 우세" and BattleOutcome.grade_of(true, 999) == "무승부", "등급 10 경계")
	_check(BattleOutcome.grade_of(false, 9000) == "패배", "패배 등급")
	var o := BattleOutcome.new()
	o.win = true
	o.reason = "cao_flagship_lost"
	o.cao_status = "killed"
	o.ending = BattleOutcome.ending_of(o)
	_check(o.ending == "J-D2" and o.ending_text().contains("전사"), "J-D2 조조 상태 치환")
	o.limited = true
	_check(BattleOutcome.ending_of(o) == "J-D6", "제한적 승리 J-D6")
	o.win = false
	o.limited = false
	o.reason = "time_limit"
	_check(BattleOutcome.ending_of(o) == "J-D10", "시계 패배 J-D10")
	o.reason = "alliance_morale_collapse"
	_check(BattleOutcome.ending_of(o) == "J-D7" and BattleOutcome.line_of(o) == "E11", "패배 J-D7·E11")
	# 후일담은 시드로 정해진다(같은 시드 = 같은 줄)
	o.win = true
	o.cao_status = "unhurt"
	o.seed = 3
	var a := BattleOutcome.line_of(o)
	_check(a == BattleOutcome.line_of(o) and EpilogueText.LINES.has(a), "후일담 결정적")

# ------------------------------------------------------------ 4 결정성
func _determinism() -> void:
	var b := BattleBrief.new()
	b.seed = 11
	b.difficulty = "입문"
	b.mode = "auto"
	var t0 := Time.get_ticks_msec()
	var r1 := AutoResolver.new(b)
	_check(r1.start(), "자동 해결 시작(스레드)")
	while not r1.poll():
		await process_frame
	var t1 := Time.get_ticks_msec()
	var r2 := AutoResolver.new(BattleBrief.from_dict(b.to_dict()))
	var o2 := r2.run_blocking()
	print("자동 해결 1판 %.1fs (스레드), 결과 %s %s %s" % [(t1 - t0) / 1000.0, r1.outcome.kind, r1.outcome.reason, r1.outcome.grade])
	_check(o2 != null and r1.outcome.to_dict() == o2.to_dict(), "같은 Brief → 같은 결과(지문 %s / %s)" % [r1.outcome.fingerprint, o2.fingerprint if o2 else "-"])
	_check(r1.outcome.cao_status != "", "적벽 결산(st.result)을 읽음")
	r1.close()
	r2.close()
	# 중단은 즉시 돌아온다
	var r3 := AutoResolver.new(b)
	r3.start()
	await process_frame
	r3.cancel()
	_check(not r3.poll(), "중단")
	r3.close()

# ------------------------------------------------------------ 5 화면
func _screen_new() -> WorldMapScreen:
	var scn := (load("res://scenes/WorldMap.tscn") as PackedScene).instantiate() as WorldMapScreen
	root.add_child(scn)
	current_scene = scn
	return scn

func _touch_tap(p: Vector2) -> void:
	for down in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0
		e.position = p
		e.pressed = down
		root.push_input(e, true)

func _pinch(c: Vector2, from_d: float, to_d: float) -> void:
	for i in 2:
		var e := InputEventScreenTouch.new()
		e.index = i
		e.position = c + Vector2(from_d * (1 if i == 0 else -1), 0)
		e.pressed = true
		root.push_input(e, true)
	var steps := 6
	for s in steps:
		var d0 := lerpf(from_d, to_d, float(s) / steps)
		var d1 := lerpf(from_d, to_d, float(s + 1) / steps)
		var m := InputEventScreenDrag.new()
		m.index = 0
		m.position = c + Vector2(d1, 0)
		m.relative = Vector2(d1 - d0, 0)
		root.push_input(m, true)
	for i in 2:
		var e := InputEventScreenTouch.new()
		e.index = i
		e.position = c
		e.pressed = false
		root.push_input(e, true)

func _buttons(n: Node, out: Array) -> void:
	if n is BaseButton and (n as Control).is_visible_in_tree() and not (n as BaseButton).disabled:
		out.append(n)
	for c in n.get_children():
		_buttons(c, out)

func _touch_sizes(s: Node, where: String) -> void:
	var btns: Array = []
	_buttons(s, btns)
	for i in TouchMetrics.TOUCH_DEVICES:
		var dev: Array = TouchMetrics.DEVICES[i]
		var dpu := TouchMetrics.dp_per_unit(dev[1], dev[2], 1.0)
		for b in btns:
			var short := minf((b as Control).size.x, (b as Control).size.y)
			_check(short * dpu >= TouchMetrics.MIN_DP - 0.01, "%s 터치 크기 %s: %.0f단위 = %.1fdp (%s)" % [where, (b as Button).text, short, short * dpu, dev[0]])

func _legacy_screen() -> void:
	var s := _screen_new()
	await _frames(6)
	_check(s.state == "browse" and s.canvas.level() == "z0", "시작은 천하 Z0")
	_check(s._cta.visible and not s._card.visible, "Z0 안내 띠")
	_touch_sizes(s, "Z0")
	var atlas := s.find_child("WorldAtlas", true, false) as Control
	_check(atlas != null and atlas.visible, "홈에서 전체 항로도 표시")
	var skirmish := s.find_child("OpenRedCliffsSkirmish", true, false) as Button
	var primary := s.find_child("OpenRedCliffs", true, false) as Button
	_check(skirmish != null and skirmish.is_visible_in_tree() and not skirmish.disabled
		and primary != null and primary.is_visible_in_tree(), "공개 지도에서 모의전·작전 선택")
	if skirmish == null:
		return
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = skirmish.get_global_rect().get_center()
		event.pressed = down
		root.push_input(event, true)
	await _seconds(1.6)
	_check(s._card.visible and s.canvas.visible and atlas != null and not atlas.visible and s.canvas.level() == "z2",
		"레거시 카드 → 형주 Z2·시나리오 카드 (%s)" % s.canvas.level())
	_check(not skirmish.is_visible_in_tree() and s.brief == null and s.resolver == null,
		"카드 진입은 출격 및 자동 해결을 시작하지 않음")
	_touch_sizes(s, "카드")
	# 두 손가락 벌리기 → 확대
	var z0 := s.canvas.zoom
	_pinch(Vector2(500, 500), 60.0, 180.0)
	await _frames(2)
	_check(s.canvas.zoom > z0 * 1.8, "두 손가락 확대 %.4f → %.4f" % [z0, s.canvas.zoom])
	# 권역 탭 → 정보 띠
	s.canvas.jump_to("z2")
	await _frames(2)
	var rp := s.canvas.w2s(WorldCanvas.v2(s.world.regions[2].pos))
	s.canvas.tap_at(rp)
	_check(s._chip.visible and s._chip_label.text.contains("남부권"), "권역 탭 정보 (%s)" % s._chip_label.text)
	# 뒤로 가기 → 한 단계 축소
	s.back()
	await _seconds(1.4)
	_check(s.canvas.level() == "z0" and s._cta.visible and not s._card.visible and atlas != null and atlas.visible,
		"뒤로 가기 → Z0")
	s.queue_free()
	await _frames(2)

# ------------------------------------------------------------ 6 왕복
func _development_sortie() -> void:
	var map := _screen_new()
	await _frames()
	var enabled := OS.get_cmdline_user_args().has("--pc-first-operation-dev")
	for route_id: String in ["front", "flank"]:
		var button := map.find_child("FirstOperationDev_" + route_id, true, false) as Button
		_check((button != null) == enabled, "development route is opt-in: " + route_id)
		if button == null:
			continue
		map.open_card()
		map.canvas.jump_to("z2")
		map._set_mode("auto")
		button.pressed.emit()
		var request := map.brief.operation_request()
		_check(request.is_read_only() and request == {
			"capability": "pc/first-operation-dev/1",
			"definition_id": "red-cliffs-first-operation-dev-v1",
			"definition_version": 1,
			"roster_id": "red-cliffs-dev-roster-v1",
			"seed": 208, "difficulty": "standard", "mode": "direct", "route_id": route_id,
		}, "development request matches P03 for " + route_id)
		map._skip.pressed.emit()
		await _frames(6)
		var battle := current_scene
		var host := battle.get_node_or_null("FirstOperationHost") if battle else null
		_check(host != null and host.operation_owner != null and battle.sim == null, "dedicated owner published for " + route_id)
		if host == null or host.operation_owner == null:
			if host != null:
				print("operation preparation failure: ", host.failure)
			return
		_check(host.frame.tick == 0 and host.frame.clock_ms == 0 and host._markers.size() == 2
			and host.frame.events.size() == 2 and host.operation_owner.drain_events().events.is_empty(),
			"initial frame and events install exactly once")
		host._start.pressed.emit()
		host.set_process(false)
		host._commands[1].pressed.emit()
		_check(host.frame.tick == 0 and host._status.text == "move", "command accepted without advancing")
		_drive_operation(host, 900 if route_id == "front" else 1500)
		_check(host.frame.clock_ms == host.frame.tick * 100, "displayed clock uses the owner tick")
		if route_id == "front":
			host._commands[2].pressed.emit()
			_drive_operation(host, 11100)
		else:
			host.find_child("Operation_withdraw", true, false).pressed.emit()
			_drive_operation(host, 650)
			host.find_child("Operation_finalize_withdrawal", true, false).pressed.emit()
			host.step_operation()
		var expected := "objective_success" if route_id == "front" else "withdrawal_success"
		var reason := "objective_conditions_met" if route_id == "front" else "withdrawal_conditions_met"
		var settled: BattleOutcome = host.settlement
		_check(settled != null and settled.kind == expected and settled.reason == reason and host.failure.is_empty(),
			"native policy settles " + route_id + ": " + str(host.failure))
		if settled == null:
			return
		print("WORLD_LINK_OPERATION %s %s %s tick=%d" % [route_id, settled.kind, settled.reason, host.frame.tick])
		var dto: Dictionary = host.frame.projection.operation.settlement
		var events: Array = host.frame.events.filter(func(event): return event.kind == "operation_settled")
		var summary: Dictionary = host.operation_owner.summary().summary
		_check(summary.settlement == dto and dto.id == settled.settlement_id and dto.kind == settled.kind
			and dto.reason == settled.reason and dto.clock_ms == host.frame.clock_ms and events.size() == 1
			and events[0].fact == dto and not host.step_operation(), "terminal DTO and one settlement event")
		host._return.pressed.emit()
		host._return.pressed.emit()
		await _frames(8)
		map = current_scene as WorldMapScreen
		var link := root.get_node("WorldLink")
		_check(map != null and map.outcome == settled and map.state == "result"
			and map._res_labels.ending.text == dto.reason and map.outcome.settlement_id == dto.id
			and is_equal_approx(map.outcome.t_s, dto.clock_ms / 1000.0)
			and link.take_outcome() == null and not link.routed(),
			"settlement returns exactly once to the map")
		if map == null:
			return
		map._result_to_world()
	map.queue_free()
	await _frames(2)

func _drive_operation(host: Node, ticks: int) -> void:
	for i in ticks:
		if not host.step_operation():
			return

func _round_trip() -> void:
	var link := root.get_node("WorldLink")
	var s := _screen_new()
	await _frames(4)
	s.open_card()
	await _seconds(1.5)
	s._set_difficulty("표준")
	s._set_mode("direct")
	s.sortie(777)
	_check(s.brief.operation_request().is_empty(), "legacy sortie has no operation request")
	await _frames(2)
	_check(s.state == "sortie" and s._skip.visible and s.canvas.input_lock, "출격 연출")
	await _seconds(2.5)
	_check(s.canvas.level() != "z0", "연출 중 확대 (%s)" % s.canvas.level())
	# 왕복은 기존 이용자의 브리핑 경로로 고정한다. 설정 파일에는 쓰지 않는다.
	GameSettings.load_cfg()
	var prologue_seen := GameSettings.prologue_seen
	GameSettings.prologue_seen = true
	s._skip.emit_signal("pressed")
	await _frames(8)
	GameSettings.prologue_seen = prologue_seen
	var battle := current_scene
	_check(battle != null and battle.name == "FleetBattle3D", "직접 지휘 → 전장 장면 (%s)" % (battle.name if battle else "null"))
	if battle == null or battle.name != "FleetBattle3D":
		return
	_check(link.routed() and link.brief.seed == 777 and battle.battle_seed == 777, "Brief 시드가 전장으로")
	var deck = battle.presentation.hud
	_check(deck.screen == "brief", "천하에서 오면 브리핑부터 (%s)" % deck.screen)
	deck.begin_battle()
	await _frames(2)
	battle.sim._end(true, "annihilation")
	battle.end_game(true, "테스트")
	await _seconds(2.2)
	await _frames(2)
	_check(deck.screen == "result", "결과 화면")
	var btn: Button = deck.screens.result.title_btn
	_check(btn.text == "천하로", "결과 버튼 '천하로' (%s)" % btn.text)
	_touch_sizes(deck.screens.result, "전장 결과")
	btn.emit_signal("pressed")
	await _frames(8)
	var w := current_scene as WorldMapScreen
	_check(w != null, "천하로 복귀")
	if w == null:
		return
	await _frames(4)
	_check(w.state == "result" and w._result.visible and w.outcome.win and w.outcome.seed == 777, "결과 카드")
	_check(not link.routed() and link.outcome == null, "결과는 한 번만 넘긴다")
	await _seconds(2.3)
	_check(w.canvas.owners_rgn.get("RGN-02") == "wu", "연합 승리 → 강릉권 손권 색")
	_touch_sizes(w, "결과 카드")

# Reject only the requested transition while keeping the real scenes and buttons.
class RejectingWorldLink extends "res://scripts/world_link.gd":
	var rejected_path := ""

	func _request_scene(path: String) -> Error:
		if path == rejected_path:
			rejected_path = ""
			return ERR_CANT_OPEN
		return super._request_scene(path)

func _prepare_failure_return() -> void:
	var map := current_scene as WorldMapScreen
	if map == null or map.outcome == null:
		_check(false, "prepare failure fixture needs the previous result")
		return
	var original_link := root.get_node("WorldLink")
	root.remove_child(original_link)
	var link := RejectingWorldLink.new()
	link.name = "WorldLink"
	root.add_child(link)
	await _exercise_map_restore(map, link)
	root.remove_child(link)
	link.free()
	root.add_child(original_link)

func _exercise_map_restore(map: WorldMapScreen, link: RejectingWorldLink) -> void:
	var result := map.outcome
	var pending := BattleOutcome.new()
	pending.seed = 456
	var previous := map.make_brief(123)
	map.brief = previous
	link.brief = previous
	link.outcome = pending
	link.rejected_path = link.BATTLE_SCENE
	map.sortie(787)
	map._skip.pressed.emit()
	_check(current_scene == map and map.state == "result" and map._result.visible
		and map.outcome == result and map.brief == previous and not map.canvas.input_lock,
		"immediate sortie rejection preserves the result and input")
	_check(link.brief == previous and link.outcome == pending
		and link.take_map_restore().is_empty(), "immediate sortie rejection preserves the handoff")

	for show_result in [true, false]:
		if not show_result:
			map._result_to_world()
			map.open_card()
			map.canvas.jump_to("z2")
		map.sortie(788)
		map.brief.difficulty = "invalid-for-test"
		map._skip.pressed.emit()
		await _frames(8)
		var battle := current_scene
		var exit_button := battle.find_child("ExitBattlePrepareError", true, false) as Button if battle else null
		_check(exit_button != null and battle.sim == null, "initial prepare failure exposes return button")
		if exit_button == null:
			return
		link.rejected_path = link.WORLD_SCENE
		exit_button.pressed.emit()
		_check(current_scene == battle and link.brief.seed == 788 and link.outcome == null
			and link.take_map_restore().is_empty(), "rejected return keeps the battle and defers restoration")
		exit_button.pressed.emit()
		await _frames(8)
		map = current_scene as WorldMapScreen
		_check(map != null, "retry returns to the map")
		if map == null:
			return
		_check(map.state == ("result" if show_result else "browse")
			and map._result.visible == show_result and map._card.visible != show_result
			and map.outcome == result and map.brief == previous and not map.canvas.input_lock
			and map._difficulty == previous.difficulty and map._mode == previous.mode,
			"retry restores the original result or card")
		_check(not link.routed() and link.outcome == pending and link.take_map_restore().is_empty(),
			"map snapshot consumed once and pending result still queued")

	map.sortie(789)
	map._skip.pressed.emit()
	await _frames(8)
	var battle := current_scene
	_check(battle != null and battle.sim != null, "normal sortie still prepares after rollback")
	if battle == null or battle.sim == null:
		return
	_check(battle.back_to_world() == OK, "normal early exit returns to the map")
	await _frames(8)
	map = current_scene as WorldMapScreen
	_check(map != null and map.state == "browse" and map._cta.visible
		and not map._card.visible and map.outcome == null and link.outcome == null
		and link.take_map_restore().is_empty(), "normal early exit opens the default map")
