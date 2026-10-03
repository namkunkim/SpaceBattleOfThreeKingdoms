extends SceneTree

# 정본 편성 검증(헤드리스): 시나리오 JSON을 읽어 세력 3·전대 14, 함종 카운터 합, 브리핑에서 화면 열기.
# 정보 패널의 함종 숫자는 코어 카운터만 쓴다(POC는 카운터가 없어 비어 있다, 리뷰 C-1).
# 리뷰 W-1 인물 ID(CHR-xxxx), W-2 난이도별 조조군 배치·배율, W-3 브리핑에서는 조조군 숨김.

func _initialize() -> void:
	call_deferred("_run")

func _frames(n := 4) -> void:
	for i in n:
		await process_frame

func _find_button(n: Node, text: String) -> Button:
	if n is Button and (n as Button).text == text and (n as Control).is_visible_in_tree():
		return n
	for c in n.get_children():
		var b := _find_button(c, text)
		if b:
			return b
	return null

func _run() -> void:
	var d := ScenarioRoster.load_scenario()
	if not TestCheck.ok(self, d.get("factions", []).size() == 3 and d.get("squadrons", []).size() == 14, "scenario loaded"): return
	var s := ScenarioRoster.squadron(d, "RC-LIU-SQ-01")
	if not TestCheck.ok(self, ScenarioRoster.ship_count(s) == 7 and ScenarioRoster.composition_text(s) == "전열 4 · 보급 1 · 요격 2", "composition %s" % ScenarioRoster.composition_text(s)): return
	for sq in d.squadrons:
		for c in sq.composition:
			if not ScenarioRoster.SHIP_TYPES.has(c.ship_type_id):
				TestCheck.ok(self, false, "unknown ship type " + str(c.ship_type_id))
				return
	# W-1: 이름·세력은 시나리오에서
	var p := Commanders.person("CHR-0207")
	if not TestCheck.ok(self, p.get("name", "") == "정보" and p.get("faction", "") == "wu" and p.get("portrait", 0) == -1, "person CHR-0207 %s" % p): return
	if not TestCheck.ok(self, Commanders.person("CHR-0134").get("portrait", -1) == 2 and Commanders.person("liu_bei").is_empty(), "portrait by CHR id"): return
	# W-2: 입문 4 · 표준 5 · 상급 7개 전대, 0.7 배율 half-up, 원래 1척 이상이면 최소 1척
	var n := {}
	for diff in ["입문", "표준", "상급", "극한"]:
		n[diff] = ScenarioRoster.deployed(d, "cao_cao", diff).size()
	if not TestCheck.ok(self, n.입문 == 4 and n.표준 == 5 and n.상급 == 7 and n.극한 == 7, "deploy by difficulty %s" % n): return
	var cao1: Dictionary = ScenarioRoster.deployed(d, "cao_cao", "표준")[0]
	var want := {"SHP-01": 1, "SHP-03": 3, "SHP-04": 6}
	for c in cao1.composition:
		if want.has(c.ship_type_id) and int(c.count) != want[c.ship_type_id]:
			TestCheck.ok(self, false, "scaled %s = %d" % [c.ship_type_id, c.count])
			return
	if not TestCheck.ok(self, ScenarioRoster.deployed(d, "liu_bei", "입문").size() == 4, "alliance same in all difficulties"): return
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await _frames()
	var deck = battle.presentation.hud
	deck.show_screen("brief")
	await _frames()
	_find_button(deck, "정본 편성").pressed.emit()
	await _frames()
	if not TestCheck.ok(self, deck.screen == "roster" and not deck.screens["roster"].data.is_empty(), "roster screen opens"): return
	if not TestCheck.ok(self, not deck.screens["roster"].reveal, "briefing hides Cao Cao's order of battle (W-3)"): return
	_find_button(deck, "돌아가기").pressed.emit()
	await _frames()
	if not TestCheck.ok(self, deck.screen == "brief", "back to brief"): return
	if not TestCheck.ok(self, battle.presentation.src.composition(battle.fleets[0].id).is_empty(), "POC has no class counters"): return
	print("ROSTER_PASS")
	quit(0)
