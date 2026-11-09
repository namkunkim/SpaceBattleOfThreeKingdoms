extends SceneTree

const Builder = preload("res://core/battle/operation_profile.gd")
const SEEDS := [0, 1, 20824, 20825, 20826, 90210, 123456789, 2147483647, 2147483648, 4294967295]
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("FAIL ", label)

func _request(seed: int = 20824) -> Dictionary:
	return {"mode": "operation", "seed": seed, "hz": 10}

func _envelope(adapter: String, definition: Variant, request: Dictionary) -> Dictionary:
	var payload := request.duplicate(true)
	payload.definition = definition
	if adapter == "host_input":
		return {"adapter": adapter, "selection": payload}
	if adapter == "replay_input":
		return {"adapter": adapter, "header": payload}
	payload.adapter = adapter
	return payload

func _has_error(result: Dictionary, code: String) -> bool:
	return result.errors.any(func(error): return error.code == code)

func _run() -> void:
	var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/i01/valid_definition.json"))
	var invalids: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/i01/invalid_definitions.json"))
	var source_text := Builder.canonical(definition)
	var child_count := root.get_child_count()
	var hashes := {}
	var builds := 0
	for repeat in 2:
		if repeat == 0:
			_legacy_check()
		var adapters: Array = Builder.ADAPTERS.duplicate()
		if repeat == 1:
			adapters.reverse()
		for seed in SEEDS:
			for adapter in adapters:
				var result := Builder.from_envelope(_envelope(adapter, definition, _request(seed)))
				builds += 1
				_check(result.ok, "a03 valid build %s/%s/%s" % [repeat, seed, adapter])
				if not result.ok:
					printerr("VALID_BUILD_ERRORS ", result.errors)
					continue
				var digest: String = result.manifest.effective_hash
				if hashes.has(seed):
					_check(hashes[seed] == digest, "a05 envelope metadata consistent")
				hashes[seed] = digest
				_check(result.effective.clock_metadata == {"tick": 0, "clock_ms": 0, "last_applied_seq": 0, "next_command_seq": 1}, "a05 configuration clock only")
				_check(result.manifest.original_i01_status == "NOT_READY" and not result.manifest.host_activation, "a06 no full I01 claim")
		if repeat == 1:
			_legacy_check()
	_check(builds == 60, "60 configuration builds")
	_check(Builder.canonical(definition) == source_text, "a03 source unchanged after 60 builds")
	var rejected := 0
	for spec in invalids:
		for adapter in Builder.ADAPTERS:
			var mutated: Variant = definition.duplicate(true)
			var request := _request()
			match spec.mutation:
				"duplicate_node": mutated.nodes.append(mutated.nodes[0].duplicate(true))
				"unknown_endpoint": mutated.edges[0].to = "Z"
				"negative_size": mutated.target_size[0] = -1
				"unsupported_version": mutated.schema_version = 999
				"missing_definition": mutated = null
				"fractional_seed": request.seed = 0.5
				"nonzero_origin": mutated.bounds[0] = 1
				"physical_obstacle": mutated.features.physical_obstacles = true
			var before := Builder.canonical(mutated)
			var result := Builder.from_envelope(_envelope(adapter, mutated, request))
			rejected += 1
			_check(not result.ok and result.effective == null and _has_error(result, spec.expected), "a02 " + spec.id + "/" + adapter)
			_check(Builder.canonical(mutated) == before, "a02 rejected source unchanged")
	_check(rejected == 24, "24 named rejection checks")
	var valid := Builder.build(definition, _request())
	if not valid.ok:
		printerr("DIRECT_VALID_ERRORS ", valid.errors)
	if valid.ok:
		_check(valid.effective.nodes[0].position == [100.0, 600.0] and valid.effective.nodes[4].position == [1600.0, 600.0], "a03 positions doubled once")
		_check(valid.effective.effect_zones[0].rect == [600.0, 100.0, 200.0, 100.0], "a03 effect rectangle")
		_check(valid.effective.regions[0].radius == 120 and valid.effective.envelope.radius == 40 and valid.effective.envelope.safety == 10, "a03 explicit source-unit regions")
		_check(valid.effective.kinematics.speed == 20 and valid.effective.kinematics.turn_deg_per_s == 27 and valid.effective.kinematics.evasion_per_speed == 4 and valid.effective.kinematics.face_turn_deg_per_s == 36, "a03 tuning arithmetic")
		_check(valid.manifest.access.free_bounds == [50.0, 50.0, 1950.0, 1150.0], "a04 synthetic free-center rectangle")
		_check(not Builder.build(valid.effective, _request()).ok, "a03 effective reinput rejected")
	var disconnected := definition.duplicate(true)
	disconnected.edges.remove_at(0)
	_check(_has_error(Builder.build(disconnected, _request()), "REQUIRED_ROUTE_DISCONNECTED"), "a04 E-J disconnects E")
	var alternate := definition.duplicate(true)
	alternate.edges.remove_at(2)
	_check(Builder.build(alternate, _request()).ok, "a04 A-C removal retains A-B alternate")
	var outside := definition.duplicate(true)
	outside.nodes[0].position = [0, 0]
	_check(_has_error(Builder.build(outside, _request()), "OUTSIDE_FREE_CENTER"), "a04 invalid center")
	var unsupported := _request()
	unsupported.construct_runtime = true
	_check(not Builder.build(definition, unsupported).ok, "a06 runtime request rejected")
	var nan_definition := definition.duplicate(true)
	nan_definition.move_mul = NAN
	_check(_has_error(Builder.build(nan_definition, _request()), "INVALID_JSON_VALUE"), "a02 in-memory NaN rejected")
	var nonuniform := definition.duplicate(true)
	nonuniform.target_size[1] = 1000
	_check(_has_error(Builder.build(nonuniform, _request()), "UNSUPPORTED_NONUNIFORM_SCALE"), "a04 unsupported nonuniform scale")
	var regressions := 0
	for path in ["envelope", "kinematics", "nodes", "edges", "regions", "effect_zones", "effects"]:
		var extra := definition.duplicate(true)
		if path in ["envelope", "kinematics"]:
			extra[path]["suffix"] = []
		elif path == "effects":
			extra.effect_zones[0].effects["suffix"] = []
		else:
			extra[path][0]["suffix"] = []
		_check(_has_error(Builder.build(extra, _request()), "UNSUPPORTED_FIELD"), "regression nested suffix " + path)
		regressions += 1
	for field in ["move_mul", "turn_mul", "face_turn", "evasion", "scale"]:
		var overflow := definition.duplicate(true)
		match field:
			"move_mul": overflow.move_mul = 1e308
			"turn_mul": overflow.turn_mul = 1e308
			"face_turn": overflow.kinematics.turn_deg_per_s = 1e308
			"evasion": overflow.move_mul = 1e-308
			"scale":
				overflow.bounds[2] = 1e-308
				overflow.bounds[3] = 1e-308
				overflow.target_size = [1e308, 1e308]
		var outcome := Builder.build(overflow, _request())
		_check(not outcome.ok and outcome.effective == null, "regression overflow " + field)
		regressions += 1
	for adapter in ["host_input", "replay_input"]:
		var extra_envelope := _envelope(adapter, definition, _request())
		var payload_key := "selection" if adapter == "host_input" else "header"
		extra_envelope[payload_key]["adapter"] = adapter
		_check(_has_error(Builder.from_envelope(extra_envelope), "UNSUPPORTED_REQUEST_FIELD"), "regression nested adapter " + adapter)
		regressions += 1
	var suffix_request := _request()
	suffix_request["suffix"] = []
	_check(_has_error(Builder.build(definition, suffix_request), "UNSUPPORTED_REQUEST_FIELD"), "regression request suffix")
	regressions += 1
	var suffix_definition := definition.duplicate(true)
	suffix_definition["suffix"] = []
	_check(_has_error(Builder.build(suffix_definition, _request()), "UNSUPPORTED_FIELD"), "regression root suffix")
	regressions += 1
	var service := definition.duplicate(true)
	service.nodes[2].position = [0, 0]
	service.regions[0].radius = 10
	_check(_has_error(Builder.build(service, _request()), "NO_SERVICE_INTERSECTION"), "regression service intersection absent")
	regressions += 1
	print("I01A_ADDITIONAL_REGRESSIONS=", regressions)
	_check(root.get_child_count() == child_count, "a06 no runtime nodes created")
	var source := FileAccess.get_file_as_string("res://core/battle/operation_profile.gd")
	for forbidden in ["BattleSim.new", "OperationState.new", "FileAccess.", "DirAccess.", "Time.", "OS."]:
		_check(not source.contains(forbidden), "a06 pure builder excludes " + forbidden)
	_check(Builder.canonical(definition) == source_text, "a06 final source unchanged")
	print("I01A_CONFIGURATION_BUILDS=", builds, " NAMED_REJECTIONS=", rejected, " CHECKS=", checks)
	print("ORIGINAL_I01_A04_A05_A06=NOT_READY; no host/runtime/save/gameplay validation")
	if failures.is_empty():
		print("I01A_OPERATION_CONFIG_PASS a01 a02 a03 a04 a05 a06")
		quit(0)
	else:
		printerr("I01A_OPERATION_CONFIG_FAIL ", failures)
		quit(1)

func _legacy_check() -> void:
	# a01: configuration passthrough, not gameplay or runtime regression.
	for profile in [PocSetup.profile(), ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json")]:
		var before := Builder.canonical(profile)
		var legacy := Builder.build(null, {"legacy_profile": profile})
		_check(legacy.ok and Builder.canonical(legacy.effective) == before, "a01 legacy configuration unchanged")
		legacy.effective.profile_id = "changed-copy"
		_check(Builder.canonical(profile) == before, "a01 legacy source does not alias output")
