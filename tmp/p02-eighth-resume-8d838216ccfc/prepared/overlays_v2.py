from overlays import overlays as original, replace, FLEET

SUITES = {
    "p02_headless_adapter": ("func check(condition: bool, label: String) -> void:", "condition", "label"),
    "p02_worker_adapter": ("func check(condition: bool, label: String) -> void:", "condition", "label"),
    "p02_replay_adapter": ("func check(value: bool, label: String) -> void:", "value", "label"),
    "p02_viewer_events": ("func require(condition: bool, message: String) -> void:", "condition", "message"),
    "i01b_private_state": ("func _check(condition: bool, label: String) -> void:", "condition", "label"),
    "i01b_service_state": ("func _check(ok: bool, message: String) -> bool:", "ok", "message"),
    "i01b_active_replace": ("func _check(condition: bool, label: String) -> void:", "condition", "label"),
    "world-clean": ("func _check(ok: bool, msg: String) -> void:", "ok", "msg"),
    "world-returning": ("func _check(ok: bool, msg: String) -> void:", "ok", "msg"),
}

def overlays(project, lane, case):
    changes = original(project, lane, case)
    def edit(path, old, new):
        changes[path] = replace(changes.get(path, (project / path).read_bytes()), old, new)
    if case in ("deployment", "guard-active", "mode-active"):
        old = 'func _pump() -> void:'
        edit(FLEET, old, "var k6_events: Array[Dictionary] = []\n\n" + old)
        old = '\tfor e in sim.drain_events_for(0):\n'
        edit(FLEET, old, old + '\t\tk6_events.append(e.duplicate(true))\n')
    if case in SUITES:
        signature, condition, label = SUITES[case]
        path = f"tests/{'world_link' if case.startswith('world-') else case}.gd"
        edit(path, signature, signature + f'\n\tprint("K6_SUITE_ASSERT ", JSON.stringify([{label}, {condition}]))')
    if case == "battle_flow":
        signature = 'static func ok(tree: SceneTree, cond: bool, msg: String = "") -> bool:'
        edit("tests/lib/check.gd", signature, signature + '\n\tprint("K6_SUITE_ASSERT ", JSON.stringify([msg, cond]))')
    if case == "autoresolve":
        old = '\t\t\tif not cmp.pass:'
        edit("tests/autoresolve.gd", old, '\t\t\tprint("K6_SUITE_ASSERT ", JSON.stringify([pol, cmp.pass]))\n' + old)
        old = '\tif not ok:'
        edit("tests/autoresolve.gd", old, '\tprint("K6_SUITE_ASSERT ", JSON.stringify(["legacy-overall", ok]))\n' + old)
    return changes
