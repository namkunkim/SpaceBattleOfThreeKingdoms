from pathlib import Path
D=Path(__file__).parent
def edit(path, fn):
 p=Path(path)
 raw=p.read_bytes()
 assert raw==(D/(p.name+".before.txt")).read_bytes(), path
 newline="\r\n" if b"\r\n" in raw else "\n"
 assert newline=="\n" or raw.count(b"\r\n")==raw.count(b"\n")
 p.write_bytes(fn(raw.decode().replace("\r\n","\n")).replace("\n",newline).encode())

def host(s):
 s=s.replace("\tinit_game()\n\t# 상품화", "\tif not init_game().ok:\n\t\tset_process(false)\n\t\tinput_node.process_mode = Node.PROCESS_MODE_DISABLED\n\t\treturn\n\t# 상품화")
 s=s.replace("func _restart() -> void:\n\tinit_game()","func _restart() -> void:\n\tif not init_game().ok:\n\t\treturn")
 start=s.index("func init_game()")
 end=s.index("# 프로필 전장",start)
 orig=s[start:end]
 reset=orig[orig.index("\tfor f in fleets:"):orig.index("\t# 천하 지도")]
 prepare=orig[orig.index("\t# 천하 지도"):orig.index("\tclock =")]
 finish=orig[orig.index("\tclock ="):]
 prepare=prepare.replace("\tbattle_seed =", "\tvar candidate_seed: int =")
 prepare=prepare.replace("\torg_errors = []", "\tvar errors := []").replace("not org.is_empty()", "not candidate_org.is_empty()").replace("profile, org,", "profile, candidate_org,").replace("\t\t\torg_errors =", "\t\t\terrors =")
 prepare=prepare.replace("\n\tload_error =", "\n\tvar message :=").replace("not org_errors.is_empty()", "not errors.is_empty()").replace("\t\tload_error =", "\t\tmessage =").replace('\t\tpush_error("%s (%s, %s)" % [load_error, profile_def, difficulty])','\t\tfallback = true').replace('\tif profile_def != "" and profile.is_empty():','\tvar fallback := false\n\tif profile_def != "" and profile.is_empty():')
 prepare=prepare[:prepare.index("\tif scen:\n\t\trig.margin")]+"""		ScenarioProfile.tune_for_play(profile, move_mul, turn_mul)
	if profile_patch.is_valid() and not profile.is_empty():
		profile_patch.call(profile)
		var invalid_path := "profile" if profile.is_empty() else ""
		if invalid_path.is_empty():
			for roster in ["ally", "foe"]:
				if not profile.get(roster) is Array:
					invalid_path = "profile." + roster
					break
		if not invalid_path.is_empty():
			return {"ok": false, "error": "invalid_candidate_profile", "path": invalid_path}
	var candidate_sim := BattleSim.new(candidate_seed, BattleRules.TICK_HZ, profile)
	# 플레이어 유비군은 처음부터 직접 지휘한다. 손권군·적군은 기존 위임 AI를 쓴다.
	for f in candidate_sim.st.fleets:
		if f.side == 0 and f.faction == "liu_bei":
			f.control = "direct"
	return {"ok": true, "seed": candidate_seed, "sim": candidate_sim,
		"ally": profile.ally.map(_with_portrait),
		"foe": profile.foe.filter(func(d): return int(d.wait) == 0).map(_with_portrait),
		"errors": errors, "message": message, "fallback": fallback, "scenario": scen}

"""
 new="""func init_game(proposed_org: Variant = null) -> Dictionary:
	var candidate_org: Dictionary = org if proposed_org == null else proposed_org
	var candidate := _prepare_game(candidate_org)
	if not candidate.ok:
		push_error("[FleetBattle3D] %s at %s" % [candidate.error, candidate.path])
		return candidate
	_publish_game(candidate, candidate_org)
	return {"ok": true}

func _prepare_game(candidate_org: Dictionary) -> Dictionary:
"""+prepare+"""func _publish_game(candidate: Dictionary, candidate_org: Dictionary) -> void:
"""+reset+"""	org = candidate_org
	battle_seed = candidate.seed
	sim = candidate.sim
	ALLY_DEF = candidate.ally
	FOE_DEF = candidate.foe
	org_errors = candidate.errors
	load_error = candidate.message
	if candidate.fallback:
		push_error("%s (%s, %s)" % [load_error, profile_def, difficulty])
	var scen: bool = candidate.scenario
	if scen:
		rig.margin = 0.4   # 시작 배율에서도 두 손가락으로 화면을 옮길 수 있게
		GameSettings.slow_mode = GameSettings.SLOW_OFF   # 선택 감속 끔(저장 설정은 건드리지 않는다)
"""+finish
 return s[:start]+new+s[end:]

def deck(s):
 start=s.index("func begin_battle(")
 end=s.index("func restart(",start)
 orig=s[start:end]
 new="""func begin_battle(org: Variant = null) -> Dictionary:
	if (org != null and org != battle.org) or battle.G.state != "brief":
		var changed_org: Variant = org if org != battle.org else null
		var result: Dictionary = battle.init_game(changed_org)
		if not result.ok:
			return result
	if battle.org_blocked():   # _start도 막지만 로그·화면을 건드리기 전에 본다
		return {"ok": true}
	_clear_log()
	battle._start()
	show_screen("")
	_cutin_fleet(battle.flag(0), Commanders.OPEN_LINE)
	return {"ok": true}

"""
 s=s[:start]+new+s[end:]
 return s.replace("\tbattle.init_game()\n","\tif not battle.init_game().ok:\n\t\treturn\n")

def org(s):
 start=s.index("func _load()")
 end=s.index("func mine()",start)
 orig=s[start:end]
 new="""func _load() -> Dictionary:
	var b: Node = deck.battle
	var scenario := ProfileLoader.read_json(ProfileLoader.read_json(b.profile_def).scenario_path)
	var profile := ScenarioProfile.load_profile(b.profile_def, b.difficulty)
	var skills := {}
	for d in scenario.get("realtime_rules", {}).get("special_skills", {}).get("skills", []):
		skills[d.id] = d
	return {"scenario": scenario, "profile": profile, "skills": skills}

func _apply_load(candidate: Dictionary) -> void:
	scn = candidate.scenario
	prof = candidate.profile
	skill_defs = candidate.skills

# 브리핑 "자동 편성으로 시작"(건너뛰기): 화면을 거치지 않고 세 세력 자동 편성으로 전투
func start_auto() -> void:
	var candidate := _load()
	var result: Dictionary = deck.begin_battle(start_org(candidate.profile, candidate.scenario))
	if not result.ok:
		return
	_apply_load(candidate)

# 브리핑에서 연다. 지금 전투에 걸린 편성(없으면 세 세력 자동 편성 = 건너뛰기와 같은 편성)에서 시작한다.
func open_org() -> void:
	var b: Node = deck.battle
	var candidate := _load()
	# 걸린 편성이 지금 전투(난이도 등)와 맞지 않으면(REVIEW-O4 #1) 유효한 유비군 함대는 두고 나머지만 채워(O4b F-3)
	# 걸린 편성과 전장도 고친 편성으로 바꾼다(뒤로 → 출격해도 같은 화면이 반복되지 않게)
	var repair_errors: Array = b.org_errors.duplicate(true)
	var repaired_squadrons := []
	if not repair_errors.is_empty():
		var r := Organization.repair(b.org, candidate.profile, candidate.scenario)
		repaired_squadrons = r.changed
		if not b.init_game(r.org.duplicate(true)).ok:
			return
	_apply_load(candidate)
	officers = Organization._officers(scn, PLAYER)
	names = {}
	for sq in scn.squadrons:
		names[sq.id] = sq.name
	notice = "" if repair_errors.is_empty() else _repair_text(repaired_squadrons, repair_errors)
	org = b.org.duplicate(true) if not b.org.is_empty() else start_org(prof, scn)
	sel = -1
	picked = {}
	search.text = ""
	deck.show_screen("org")
	_refresh()

"""
 return s[:start]+new+s[end:]

if __name__=="__main__":
 edit("scripts/FleetBattle3D.gd",host)
 edit("hud/ui_kit/command_deck.gd",deck)
 edit("hud/ui_kit/org_screen.gd",org)
