extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog = Commanders.PortraitCatalog
	if not TestCheck.ok(self, catalog.PATHS.size() == 501, "501 runtime portraits"): return
	for path in catalog.PATHS:
		if not TestCheck.ok(self, ResourceLoader.exists(path), "portrait import: " + path): return
	for id in ["SHJ-F090", "SHJ-F091", "SHJ-F102"]:
		if not TestCheck.ok(self, Commanders.portrait_path(Commanders.portrait_index(id)).ends_with("-western-v2.png"), "Western revision: " + id): return
	if not TestCheck.ok(self, Commanders.portrait_index("CHR-0128") == 0 and Commanders.portrait_index("CHR-0134") == 2 and Commanders.portrait_index("CHR-0034") == 4, "legacy index compatibility"): return
	if not TestCheck.ok(self, Commanders.portrait_index("CHR-0256") == Commanders.portrait_index("SHJ-O134"), "same-name faction mapping"): return
	if not TestCheck.ok(self, Commanders.portrait_index("CHR-0162") == -1 and Commanders.portrait_index("unknown") == -1, "unnamed groups have no invented identity"): return
	var battle = (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	var portraits := {}
	for f in battle.alive(0):
		var expected := Commanders.portrait_index(f.fname)
		if not TestCheck.ok(self, expected >= 0 and f.portrait == expected, "live commander portrait: " + f.fname): return
		portraits[f.portrait] = true
		var texture: Texture2D = battle._portrait_tex(f.portrait)
		if not TestCheck.ok(self, texture is AtlasTexture and texture.get_size() == Vector2(561, 561) and texture.atlas.resource_path == Commanders.portrait_path(expected), "HUD crop preserves face proportions: " + f.fname): return
		if not TestCheck.ok(self, texture == battle._portrait_tex(f.portrait), "portrait texture cache"): return
	if not TestCheck.ok(self, portraits.size() == battle.alive(0).size(), "all allied commanders have distinct portraits"): return
	for d in battle.ALLY_DEF:
		if not TestCheck.ok(self, d.p == Commanders.portrait_index(str(d.commander_id)), "briefing ID portrait"): return
	if not TestCheck.ok(self, battle._with_portrait({"commander_id": "CHR-0162", "p": 0}).p == -1 and battle._portrait_tex(-1) is GradientTexture2D, "unknown individual does not borrow Liu Bei's face"): return
	# Core state still has the original rule/profile portrait number; mapping is presentation-only.
	for f in battle.sim.st.fleets:
		if not TestCheck.ok(self, f.portrait == 0, "core profile unchanged"): return
	print("PORTRAITS_PASS")
	battle.queue_free()
	await process_frame
	await process_frame
	quit(0)
