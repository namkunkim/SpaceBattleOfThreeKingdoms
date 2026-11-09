extends SceneTree

const Private := preload("res://core/battle/operation_private_state.gd")
const Adapter := preload("res://core/battle/operation_runtime_adapter.gd")
const SimScript := preload("res://core/battle/battle_sim.gd")
const Decision := preload("res://core/battle/decisions.gd")
const PROFILE := "res://data/profiles/red_cliffs_rt.json"
const DIFFICULTY := "표준"
const SEED := 91231
const NAMES := ["production_constructor_decision_board", "restricted_adapter_baseline_restore", "restricted_adapter_decision_scenario_rejection"]

var checks := 0
var failed := false
var completed: Array[String] = []
var cards: Dictionary
var observations := {}

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failed = true
		push_error("P03_ACTIVE_PRODUCT_FAIL " + label)
	return condition

func _run() -> void:
	if _check(Private._classes() == "", "canonical private transitive class map"):
		if _production_constructor():
			completed.append(NAMES[0])
			var input := _restricted_input()
			if _restricted_baseline(input):
				completed.append(NAMES[1])
			if _restricted_rejection(input):
				completed.append(NAMES[2])
	_check(completed == NAMES, "all named cases")
	print("P03_ACTIVE_PRODUCT_RESULT ", JSON.stringify({"cases": completed, "checks": checks,
		"engine_path": OS.get_executable_path(), "engine_pid": OS.get_process_id(),
		"observations": observations, "ok": not failed}))
	quit(1 if failed else 0)

func _production_constructor() -> bool:
	var definition := ProfileLoader.read_json(PROFILE)
	var scenario := ProfileLoader.read_json(definition.scenario_path)
	cards = scenario.get("realtime_rules", {}).get("decision_cards", {})
	_check(not cards.is_empty(), "nonempty card data from scenario path")
	var profile := Organization.load_auto(PROFILE, DIFFICULTY)
	if not _check(not profile.is_empty() and profile.get("profile_id") == definition.profile_id
		and profile.get("difficulty") == DIFFICULTY,
		"standard automatic organization produced the named Red Cliffs profile without fallback"):
		return false
	_check(profile.scenario.realtime_rules.decision_cards == cards, "automatic profile contains canonical card data")
	var sim := BattleSim.new(SEED, BattleRules.TICK_HZ, profile)
	var decision := sim.decisions
	_check(is_same(sim.get_script(), SimScript) and sim.get_script().resource_path == "res://core/battle/battle_sim.gd",
		"canonical BattleSim")
	_check(decision != null, "constructor activated DecisionBoard")
	if decision != null:
		_check(is_same(decision.get_script(), Decision) and decision.get_script().resource_path == "res://core/battle/decisions.gd",
			"canonical DecisionBoard")
		_check(is_same(decision.sim, sim), "DecisionBoard owns original sim back-reference")
	observations.production = {"profile": PROFILE, "difficulty": DIFFICULTY, "scenario": definition.scenario_path,
		"cards": cards.size(), "decision_board": decision != null}
	for field in ["morale", "victory", "salvo", "detect", "supply", "chain", "cmd", "assault", "skills", "decisions"]:
		var module: Variant = sim.get(field)
		if module != null:
			module.sim = null
	return not failed

func _restricted_input() -> Dictionary:
	var rules: Dictionary = PocSetup.profile().rules
	return {"mode": "operation", "format": Adapter.FORMAT, "seed": SEED, "hz": BattleRules.TICK_HZ,
		"initial_controls": ["direct", "direct"], "policy": "none", "max_ticks": 5,
		"profile": {"profile_id": "p03-active-product-control", "rules": rules,
			"ally": [{"name": "A", "role": "A", "ships": 30, "lv": 1, "x": 500, "y": 500, "p": 0, "flag": true}],
			"foe": [{"name": "B", "role": "B", "ships": 30, "lv": 1, "x": 2600, "y": 1500, "p": 0, "flag": true}],
			"reinf": []}}

func _restricted_baseline(input: Dictionary) -> bool:
	var created := Adapter.create(input)
	if not _check(created.ok, "restricted adapter creation"): return false
	var owner: OperationPrivateState = created.owner
	var initial := owner._sim
	_check(is_same(owner.get_script(), Private) and is_same(initial.get_script(), SimScript), "canonical owner and sim identity")
	_check(owner._ready and not owner._busy, "initial ready and idle")
	_check(initial.decisions == null, "initial decisions absent")
	var captured := owner.capture_completed()
	if _check(captured.ok, "C0 capture"):
		_check(owner.advance().ok and owner._sim.st.tick == 1, "advance to tick 1")
		var restored := owner.restore_completed(captured.packet)
		_check(restored.ok, "same context restore")
		_check(not is_same(initial, owner._sim), "sim replaced")
		_check(owner._sim.st.tick == 0, "replacement at tick 0")
		_check(owner._sim.decisions == null, "replacement decisions absent")
		_check(owner._ready and not owner._busy, "replacement ready and idle")
		observations.baseline = {"restore": restored, "tick": owner._sim.st.tick,
			"decision_board": owner._sim.decisions != null, "busy": owner._busy}
	owner.close()
	return not failed

func _restricted_rejection(input: Dictionary) -> bool:
	var candidate := input.duplicate(true)
	candidate.profile.scenario = {"realtime_rules": {"decision_cards": cards.duplicate(true)}}
	var frozen := var_to_bytes(candidate)
	var baseline := candidate.duplicate(true)
	baseline.profile.erase("scenario")
	_check(var_to_bytes(baseline) == var_to_bytes(input), "scenario is the only input delta")
	var result := Adapter.create(candidate)
	_check(result == {"ok": false, "error": "unsupported_scenario", "path": "profile"}, "exact scenario refusal")
	_check(not result.has("owner"), "no owner returned")
	_check(var_to_bytes(candidate) == frozen, "input preserved byte for byte")
	if result.has("owner"):
		result.owner.close()
	observations.scenario_rejection = result
	return not failed
