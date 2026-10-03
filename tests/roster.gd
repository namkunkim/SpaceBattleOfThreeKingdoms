extends SceneTree

# 정본 편성 검증(헤드리스): 시나리오 JSON을 읽어 세력 3·전대 14, 함종 카운터 합, 브리핑에서 화면 열기.
# 정보 패널의 함종 숫자는 코어 카운터만 쓴다(POC는 카운터가 없어 비어 있다, 리뷰 C-1).

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
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await _frames()
	var deck = battle.presentation.hud
	deck.show_screen("brief")
	await _frames()
	_find_button(deck, "정본 편성").pressed.emit()
	await _frames()
	if not TestCheck.ok(self, deck.screen == "roster" and not deck.screens["roster"].data.is_empty(), "roster screen opens"): return
	_find_button(deck, "브리핑으로").pressed.emit()
	await _frames()
	if not TestCheck.ok(self, deck.screen == "brief", "back to brief"): return
	if not TestCheck.ok(self, battle.presentation.src.composition(battle.fleets[0].id).is_empty(), "POC has no class counters"): return
	print("ROSTER_PASS")
	quit(0)
