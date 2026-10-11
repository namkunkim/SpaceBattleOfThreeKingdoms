extends SceneTree

# O4 편성 화면(헤드리스): 브리핑 → 편성 → 전투, 확정 잠금, 자동 편성 버튼, 출전 토글, 기함 잠금, 장수 맞바꿈, 함선 ±,
# 정사 편성으로 초기화(유비군만 정사 + 한도 미달 경고), 건너뛰기("자동 편성으로 시작") = 세 세력 자동 편성(Q81)이고
# 화면 첫 상태와 같은 결과, 조조 비용 비율이 난이도 목표 ±0.05(O2 Q82). apply 실패 가드(REVIEW-O1b #2). 버튼은 실제 위치를 눌러 본다.

func _initialize() -> void:
	call_deferred("_run")

func _click(c: Control) -> void:
	var p := c.get_global_rect().get_center()
	for down in [true, false]:
		var m := InputEventMouseButton.new()
		m.device = InputEvent.DEVICE_ID_EMULATION   # 터치 흉내(마우스와 같은 경로)
		m.button_index = MOUSE_BUTTON_LEFT
		m.position = p
		m.global_position = p
		m.pressed = down
		m.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		root.push_input(m, true)

func _find(n: Node, text: String) -> Button:
	if n is Button and (n as Button).text == text and (n as Control).is_visible_in_tree() and not n.is_queued_for_deletion():
		return n
	for c in n.get_children():
		var b := _find(c, text)
		if b:
			return b
	return null

func _frames(n := 4) -> void:
	for i in n:
		await process_frame

func _fp(battle: Node) -> String:
	for i in 300:
		battle.sim.step()
		battle.sim.drain_events()
	return battle.sim.fingerprint()

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await _frames()
	var deck = battle.presentation.hud
	deck.show_screen("brief")
	await _frames()
	_click(_find(deck, "편  성"))
	await _frames()
	var o = deck.screens["org"]
	if not TestCheck.ok(self, deck.screen == "org", "brief -> org (%s)" % deck.screen): return
	var auto: Dictionary = o.start_org(o.prof, o.scn)
	if not TestCheck.ok(self, o.org == auto and o.errors.is_empty() and not o.confirm.disabled, "starts at 3-faction auto org, confirm open"): return
	var mine: Array = o.mine()
	if not TestCheck.ok(self, mine.size() >= 2 and mine.all(func(i): return o.org.fleets[i].faction_id == "liu_bei"), "only liu_bei fleets %s" % [mine]): return
	var flag := -1
	var other := -1
	for i in mine:
		if o.is_flag(i):
			flag = i
		elif other < 0:
			other = i
	# 기함 잠금: 출전 토글이 꺼져 있고 눌러도 그대로, 제독 칸도 잠김
	var tog: Button = _find(o.fleets_box, "출전")   # 첫 카드 = 기함
	if not TestCheck.ok(self, flag == mine[0] and tog.disabled, "flag toggle disabled"): return
	_click(tog)
	await _frames()
	o.toggle(flag)
	o.press(flag, "admiral")
	await _frames()
	if not TestCheck.ok(self, o.org.fleets[flag].on and o.picked.is_empty(), "flag stays on, admiral slot locked"): return
	# 출전 토글: 끄면 장수가 대기 풀로, 켜면 빈 함대라 확정 잠금 + 사유 문구
	var adm: String = o.org.fleets[other].admiral
	o.sel = other
	o.toggle(other)
	await _frames()
	if not TestCheck.ok(self, not o.org.fleets[other].on and _find(o.pool_box, o._card(adm)) != null, "toggle off -> officer in pool"): return
	if not TestCheck.ok(self, not o.confirm.disabled, "fleet off still valid"): return
	_click(_find(o.fleets_box, "대기"))
	await _frames()
	if not TestCheck.ok(self, o.org.fleets[other].on and o.confirm.disabled, "toggle on empty fleet -> confirm locked"): return
	if not TestCheck.ok(self, "제독이 없습니다" in o.msg.text and "함선이 0척입니다" in o.msg.text, "reason text: %s" % o.msg.text): return
	_click(o.confirm)
	await _frames()
	if not TestCheck.ok(self, deck.screen == "org" and battle.G.state == "brief", "locked confirm does nothing"): return
	# apply 실패 가드(REVIEW-O1b #2): 화면 갱신 없이 편성을 깨뜨려 버튼이 켜진 채여도 확정은 apply의 errors를 보고 멈춘다
	var save: Dictionary = o.org.duplicate(true)
	o.org = Organization.default_org(o.prof)
	o._refresh()
	o.org.fleets[flag].on = false   # flag_off, _refresh 없이
	if not TestCheck.ok(self, not o.confirm.disabled, "guard setup: confirm still enabled"): return
	_click(o.confirm)
	await _frames()
	if not TestCheck.ok(self, deck.screen == "org" and battle.G.state == "brief" and o.confirm.disabled and "기함 함대는 출전해야 합니다" in o.msg.text, "apply errors -> locked + reason: %s" % o.msg.text): return
	o.org = save
	o._refresh()
	# 장수 배정: 빈 제독 칸을 누르고 풀 장수를 누른다(맞바꿈)
	o.press(other, "admiral")
	o.press(-1, "", adm)
	await _frames()
	if not TestCheck.ok(self, o.org.fleets[other].admiral == adm, "slot <- pool officer"): return
	# 칸끼리 맞바꿈: 이 함대 제독 ↔ 기함 부제독
	var vice: String = o.org.fleets[flag].vice
	o.press(other, "admiral")
	o.press(flag, "vice")
	if not TestCheck.ok(self, o.org.fleets[other].admiral == vice and o.org.fleets[flag].vice == adm, "slot <-> slot swap"): return
	# 함선 +는 한도까지만, −는 0에서 멈춤
	await _frames()
	var plus: Button = null
	for b in o.detail.find_children("*", "Button", true, false):
		if b.text == "+" and not b.is_queued_for_deletion():
			plus = b
			break
	_click(plus)
	await _frames()
	if not TestCheck.ok(self, o.ship_count(other, "SHP-01") == 1, "+ by click"): return
	for i in 1000:
		o.add_ship(other, "SHP-08", 1)
	if not TestCheck.ok(self, o.cap_left(other) < int(o.prof.combat.ship_types["SHP-08"].cost) and o.cap_left(other) >= 0, "+ stops at limit"): return
	if not TestCheck.ok(self, Organization.tier_of(o.org.fleets[other], o.scn, o.prof) == 0 and o.tier_text(other) == "", "no tier at limit"): return
	# 한도 초과(통솔 낮은 제독으로 교체) → 경고 문구, 확정은 막지 않는다
	var weak := ""
	for id in o.officers:
		if not o.org.fleets.any(func(fl): return fl.on and Organization._people(fl).has(id)) and (weak == "" or int(o.officers[id].command) < int(o.officers[weak].command)):
			weak = id
	o.press(other, "admiral")
	o.press(-1, "", weak)
	await _frames()
	if not TestCheck.ok(self, Organization.tier_of(o.org.fleets[other], o.scn, o.prof) > 0 and "지휘 한도 초과" in o.tier_text(other) and o.errors.is_empty(), "over limit warns only: %s" % o.tier_text(other)): return
	# 자동 편성 버튼 = Organization.auto_fill
	var want := Organization.auto_fill(o.org, "liu_bei", o.scn, o.prof)
	_click(_find(deck, "자동 편성"))
	await _frames()
	if not TestCheck.ok(self, o.org == want and o.errors.is_empty() and not o.confirm.disabled, "auto fill button"): return
	for i in mine:
		var fl: Dictionary = o.org.fleets[i]
		if not TestCheck.ok(self, fl.staff.size() == 3 and fl.vice != "" and Organization.cost_of(fl, o.prof) <= Organization.limit_of(fl, o.scn, o.prof), "auto filled " + fl.squadron_id): return
	# 초기화
	_click(_find(deck, "정사 편성으로 초기화"))
	await _frames()
	if not TestCheck.ok(self, o.org == o.start_org(o.prof, o.scn, false), "reset: liu default, ai auto"): return
	if not TestCheck.ok(self, o.under_text(flag) != "" and o.errors.is_empty(), "reset warns under limit, not blocking"): return
	for fl in o.org.fleets:
		if fl.faction_id == "liu_bei":
			var d: Dictionary = Organization.default_org(o.prof).fleets.filter(func(x): return x.squadron_id == fl.squadron_id)[0]
			if not TestCheck.ok(self, fl == d, "reset liu fleet = default " + fl.squadron_id): return
	# 확정: 자동 편성 사본으로 전투 시작(아군 제독이 바뀐다)
	_click(_find(deck, "자동 편성"))
	await _frames()
	var chosen: Dictionary = o.org.duplicate(true)
	_click(o.confirm)
	await _frames()
	if not TestCheck.ok(self, deck.screen == "" and battle.G.state == "play" and battle.org == chosen, "confirm -> battle with org"): return
	var applied := Organization.apply(o.prof, chosen, o.scn)
	if not TestCheck.ok(self, battle.ALLY_DEF.map(func(d): return d.commander_id) == applied.ally.map(func(d): return d.commander_id), "battle uses applied org"): return
	# 건너뛰기 경로 = 세 세력 자동 편성 = 화면 첫 상태(같은 시드로 지문 비교)
	deck.to_title()
	deck.show_screen("brief")
	await _frames()
	seed(7)
	battle.org = auto.duplicate(true)
	battle.init_game()
	var fp_default := _fp(battle)
	seed(7)
	battle.org = {}   # 건너뛰기가 실제로 전장을 다시 만드는지 보려고 비워 둔다
	_click(_find(deck, "자동 편성으로 시작"))   # 누르는 즉시 전장을 다시 만든다. 프레임을 기다리면 전투가 흘러 지문이 달라진다
	var fp_skip := _fp(battle)
	if not TestCheck.ok(self, battle.org == auto and battle.G.state == "play", "skip -> battle with 3-faction auto org"): return
	if not TestCheck.ok(self, fp_skip == fp_default, "skip == screen initial org result"): return
	# Q83: 편성 사본 없는 기본 경로(load_auto)도 같은 결과
	seed(7)
	battle.org = {}
	battle.init_game()
	if not TestCheck.ok(self, _fp(battle) == fp_default, "default path (no org) == skip"): return
	var sum := {"ally": 0, "cao": 0}
	for fl in auto.fleets:   # = 건너뛰기 편성(위에서 확인)
		if fl.on:
			sum["cao" if fl.faction_id == "cao_cao" else "ally"] += Organization.cost_of(fl, o.prof)
	var target := float(o.prof.scenario.difficulty_profile.target_cost_ratio)
	if not TestCheck.ok(self, absf(float(sum.cao) / float(sum.ally) - target) <= 0.05, "skip cao ratio %.3f vs %.2f" % [float(sum.cao) / float(sum.ally), target]): return
	print("ORGANIZATION_UI_PASS")
	quit(0)
