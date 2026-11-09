extends SceneTree
const NATURAL = "res://tmp/p02-third-20261108/matrix/natural.json"
const OUT = "res://tmp/p03-parallel-cursor-20261108/oracle-a.native"
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    if load("res://core/battle/battle_sim.gd").resource_path != "res://core/battle/battle_sim.gd":
        push_error("canonical path mismatch")
        quit(1)
        return
    for path in ["res://scripts/world_link.gd", "res://scripts/world/battle_brief.gd", "res://scripts/world/battle_outcome.gd"]:
        if load(path).resource_path != path:
            push_error("autoload class path mismatch: " + path)
            quit(1)
            return
    var bundle: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(NATURAL))
    var sim := BattleSim.new(bundle.input.seed, bundle.input.hz, bundle.input.profile)
    for i in bundle.input.initial_controls.size():
        sim.st.fleets[i].control = bundle.input.initial_controls[i]
    sim.projection(0)
    var a := BattleSim.command(0, [9999], "stop", -1, Vector2.ZERO, {})
    a.tick = 0
    sim.queue(a)
    var events: Array = []
    while not sim.st.over and sim.st.tick < bundle.input.max_ticks:
        sim.step()
        events.append_array(sim.drain_events())
    var st := sim.st
    var summary := {"tick": st.tick, "clock_ms": st.clock_ms, "over": st.over,
        "win": st.over and st.win, "reason": st.end_reason if st.over else "timeout",
        "t": st.end_ms / 1000.0 if st.over else st.clock_s(), "end_tick": st.end_tick, "end_ms": st.end_ms,
        "lost": st.lost / 1000.0, "killed": st.killed / 1000.0,
        "reinf_t": st.reinf_ms / 1000.0 if st.reinf else -1.0,
        "ally_alive": st.alive(0).size(), "foe_alive": st.alive(1).size(),
        "fp": sim.fingerprint(), "commands": sim.command_log.size()}
    var rejection := events.any(func(e): return e.kind == "rejected" and e.value == "no_selection" and e.tick == 0)
    var terminal: bool = not events.is_empty() and events[-1].kind == "battle_end" and events[-1].tick == st.end_tick
    var ok: bool = st.over and st.tick == 1221 and st.end_tick == 1221 and st.clock_ms == 122050 and st.end_ms == 122050 and st.tick < 17999 and 17999 < bundle.input.max_ticks and terminal and rejection and sim.command_log == [a]
    var data := {"summary":summary,"events":events,"event_count":events.size(),"log":sim.command_log,"commands_consumed":1,"ok":ok}
    var file := FileAccess.open(OUT, FileAccess.WRITE)
    file.store_var(data)
    file.close()
    for field in ["salvo", "detect", "supply"]:
        var module: Variant = sim.get(field)
        if module: module.sim = null
    print("ORACLE_RESULT " + JSON.stringify({"ok":ok,"tick":st.tick,"end_tick":st.end_tick,"clock_ms":st.clock_ms,"end_ms":st.end_ms,"terminal":terminal,"rejection":rejection,"engine_pid":OS.get_process_id(),"engine_path":OS.get_executable_path()}))
    quit(0 if ok else 1)

