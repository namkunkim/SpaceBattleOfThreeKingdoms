extends SceneTree

# P8c 장수 특기 UI(헤드리스): 정보 패널 특기 줄.
#  1. 단일 선택 아군: 버튼 3·터치 크기, 슬롯 이름 / 2. 발동: skill 명령 → 알림(경고 아님)·"발동 중"·끝나면 "사용함"
#  3. 다시 누르면 skill_used 거부 토스트 / 4. 사유 코드 문구(데이터 requires 키 전부 포함)
#  5. 적 함대·다중 선택은 특기 줄 없음, 적 항목에 skills 키 없음 / 6. 받은 효과 칩: 적이 건 효과는 이름·남은 초만(시전자 숨김, Q97)
#  7. 위임 함대에 발동 → 직접 지휘 / 8. 강궁 효과 중 사거리 고리 값(ranges)이 ×1.3

func _initialize() -> void:
	call_deferred("_run")

func _frames(n := 3) -> void:
	for i in n:
		await process_frame

func _select(battle: Node, fs: Array) -> void:
	battle.selected.clear()
	for f in fs:
		battle.selected.append(f)
	battle.inspect = null

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await _frames()
	var deck = battle.presentation.hud
	deck.begin_battle()
	await _frames()
	var core: BattleSim = battle.sim
	if not TestCheck.ok(self, core.skills != null and battle.G.state == "play", "특기 규칙이 있는 전투"): return
	var events := []
	battle.battle_event.connect(func(k, t, id): events.append([k, t, id]))

	# 아군 함대 중 자기 대상(self) 슬롯이 준비된 함대
	var me = null
	var slot := -1
	for f in battle.alive(0):
		for i in f.skills.get("slots", []).size():
			var s: Dictionary = f.skills.slots[i]
			if s.id != "" and s.block == "" and s.target == "self" and float(core.skills.defs[s.id].duration_s) > 0.0:
				me = f
				slot = i
				break
		if me:
			break
	if not TestCheck.ok(self, me != null, "준비된 자기 대상 슬롯이 있는 아군 함대"): return

	# --- 1. 버튼 3 ---
	_select(battle, [me])
	deck._refresh_skills()
	await _frames()
	var bar = deck.skill_bar
	if not TestCheck.ok(self, bar.visible and bar.btns.size() == 3 and bar.btns.all(func(b): return b.is_visible_in_tree()), "단일 선택 아군: 특기 버튼 3개"): return
	if not TestCheck.ok(self, bar.btns.all(func(b): return b.size.y >= 56.0 and b.size.x >= 120.0), "버튼 크기(터치) %s" % str(bar.btns[0].size)): return
	if not TestCheck.ok(self, bar.btns[slot].slot.name == me.skills.slots[slot].name and bar.btns[slot].status()[0].begins_with("준비"), "슬롯 이름·준비 %s" % str(bar.btns[slot].status())): return
	if not TestCheck.ok(self, deck.info.size.y >= deck.INFO_L1 + bar.H - 1.0, "정보 패널이 특기 줄만큼 늘어남 %s" % deck.info.size.y): return
	var sid: String = me.skills.slots[slot].id
	var nm: String = me.skills.slots[slot].name

	# --- 2. 발동 ---
	bar.btns[slot].pressed.emit()
	battle._sync()
	deck._refresh_skills()
	var ev: Array = events.filter(func(e): return e[0] == "skill")
	if not TestCheck.ok(self, ev.size() == 1 and nm in ev[0][1] and ev[0][2] == me.id, "발동 알림 %s" % str(events)): return
	if not TestCheck.ok(self, deck.toast_good and nm in deck.toast_text, "알림 띠는 경고 아님 %s" % deck.toast_text): return
	if not TestCheck.ok(self, core.command_log[-1].kind == "skill" and int(core.command_log[-1].args.slot) == slot, "skill 명령이 명령 기록에"): return
	var st: Array = bar.btns[slot].status()
	if not TestCheck.ok(self, st[0].begins_with("발동 중") and int(me.skills.slots[slot].uses_left) == 0, "발동 중 남은 초 %s" % str(st)): return
	# 효과를 끝낸다
	var cf: FleetState = core.st.by_id(me.id)
	for x in cf.fx:
		if x.id == sid:
			x.until = core.st.tick + 1
	core.step()
	battle._pump()
	deck._refresh_skills()
	if not TestCheck.ok(self, bar.btns[slot].status()[0] == "사용함" and bar.btns[slot].spent(), "끝나면 사용함 %s" % str(bar.btns[slot].status())): return

	# --- 3. 다시 누르면 거부 ---
	events.clear()
	bar.btns[slot].pressed.emit()
	if not TestCheck.ok(self, events.any(func(e): return e[0] == "toast" and e[1] == battle.REJECT.skill_used) and not deck.toast_good, "skill_used 토스트 %s" % str(events)): return

	# --- 4. 사유 코드 문구 ---
	var codes := ["skill_used", "skill_no_slot", "commander_down", "skill_no_target", "assault_blocked", "chain_host", "chain_letter_used", "chain_spent"]
	for id in core.skills.defs:
		for k in core.skills.defs[id].get("requires", {}):
			codes.append("skill_requires_" + k)
	for code in codes:
		if not TestCheck.ok(self, battle.REJECT.has(code), "문구 있음: %s" % code): return
	if not TestCheck.ok(self, battle.reject_text("skill_requires_new_key") != battle.reject_text("x_unknown") and battle.reject_text("x_unknown") == "명령을 수행할 수 없습니다", "모르는 requires는 특기 일반 문구"): return

	# --- 5. 적·다중 선택 ---
	var foe = null
	for f in battle.fleets:
		if f.side == 1 and not f.dead:
			foe = f
			break
	if not TestCheck.ok(self, foe != null, "보이는 적 함대"): return
	if foe:
		if not TestCheck.ok(self, foe.skills.is_empty(), "적 항목에 skills 없음"): return
		_select(battle, [])
		battle.inspect = foe
		deck._refresh_skills()
		if not TestCheck.ok(self, not bar.visible, "적 함대 정보: 특기 줄 없음"): return
	for q in core.projection(0).squadrons:
		if q.side == 1 and q.has("skills"):
			TestCheck.ok(self, false, "적 투영에 skills 키")
			return
	var two: Array = battle.alive(0).slice(0, 2)
	_select(battle, two)
	deck._refresh_skills()
	await _frames()
	if not TestCheck.ok(self, not bar.visible and deck.info.size.y < deck.INFO_L1 + 1.0, "다중 선택: 특기 줄 숨김"): return

	# --- 6. 받은 효과 칩(적이 건 교란) ---
	var foe_core: FleetState = null
	for g in core.st.fleets:
		if g.side == 1:
			foe_core = g
			break
	var dis := "SK-T-DISRUPT"
	cf.fx.append({"id": dis, "src": foe_core.id, "until": core.st.tick + 300, "e": core.skills.defs[dis].effects, "r": 0.0})
	battle._sync()
	_select(battle, [me])
	deck._refresh_skills()
	var rc: Array = bar.received()
	if not TestCheck.ok(self, rc.size() == 1 and rc[0].foe and not rc[0].has("src") and rc[0].name == core.skills.defs[dis].name and float(rc[0].left_s) > 0.0, "적이 건 효과: 이름·남은 초만 %s" % str(rc)): return
	cf.fx = cf.fx.filter(func(x): return x.id != dis)

	# --- 7. 위임 함대에 발동 → 직접 지휘 ---
	var other = null
	var oslot := -1
	for f in battle.alive(0):
		if f == me:
			continue
		for i in f.skills.get("slots", []).size():
			if f.skills.slots[i].id != "" and f.skills.slots[i].uses_left > 0:
				other = f
				oslot = i
				break
		if other:
			break
	if not TestCheck.ok(self, other != null, "남은 슬롯이 있는 다른 아군 함대"): return
	if other:
		core.st.by_id(other.id).control = "delegate"
		battle._sync()
		_select(battle, [other])
		deck._refresh_skills()
		if not TestCheck.ok(self, "직접 지휘" in bar.btns[oslot].tooltip_text, "위임 함대 버튼 안내"): return
		bar.btns[oslot].pressed.emit()
		deck._refresh_skills()
		if not TestCheck.ok(self, other.control == "direct", "발동하면 직접 지휘 %s" % other.control): return

	# --- 8. 강궁: 효과 중 사거리 ×1.3 ---
	var hz: FleetState = cf
	var base: float = float(hz.ranges.get("artillery", 0.0))
	if not TestCheck.ok(self, base > 0.0, "포격 사거리 있음"): return
	if base > 0.0:
		var hd: Dictionary = core.skills.defs["SK-U-HUANGZHONG"]
		hz.fx.append({"id": "SK-U-HUANGZHONG", "src": hz.id, "until": core.st.tick + 300, "e": hd.effects, "r": 0.0})
		core.salvo.refresh_range(hz)
		battle._sync()
		if not TestCheck.ok(self, absf(float(me.ranges.artillery) - base * 1.3) < 1.0, "강궁 중 화면 사거리 %s → %s" % [base, me.ranges.artillery]): return
	print("SPECIAL_SKILLS_UI_PASS")
	quit(0)
