extends SceneTree
const Replay = preload("res://core/battle/operation_replay.gd")
const Adapter = preload("res://core/battle/operation_runtime_adapter.gd")
const BASE = "res://tmp/p02-third-20261108/matrix/"
const ORACLE = "res://tmp/p03-parallel-cursor-20261108/oracle-a.native"
var ids: Array = []
var cases: Array = []
var failed := 0
var saved_log: Variant
var saved_summary: Variant
func ck(name: String, n: int, value: bool) -> void:
    var id := "%s:%d" % [name,n]
    if id in ids: failed += 1
    ids.append(id)
    if not value:
        failed += 1
        printerr("CHECK_FAIL " + id)
    print("CHECK %s %s" % [id, "PASS" if value else "FAIL"])
func create(data: Dictionary) -> Dictionary:
    return Adapter.create(data.input)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    if load("res://core/battle/operation_replay.gd").resource_path != "res://core/battle/operation_replay.gd" or load("res://core/battle/operation_private_state.gd").resource_path != "res://core/battle/operation_private_state.gd":
        push_error("canonical path mismatch")
        quit(1)
        return
    for path in ["res://scripts/world_link.gd", "res://scripts/world/battle_brief.gd", "res://scripts/world/battle_outcome.gd"]:
        if load(path).resource_path != path:
            push_error("autoload class path mismatch: " + path)
            quit(1)
            return
    var natural: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE + "natural.json"))
    var late: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE + "late.json"))
    var file := FileAccess.open(ORACLE, FileAccess.READ)
    var oracle: Dictionary = file.get_var()
    file.close()
    var a := {"tick":0,"side":0,"ids":[9999],"kind":"stop","target_id":-1,"point":[0,0],"args":{}}
    var b: Dictionary = late.commands[0]
    var expected_a := {"tick":0,"side":0,"ids":[9999],"kind":"stop","target_id":-1,"point":Vector2.ZERO,"args":{}}
    var invalid: Dictionary = b.duplicate(true)
    invalid.kind = "unsupported_for_probe"
    var precondition: bool = natural.input == late.input and oracle.ok and oracle.summary.over and oracle.summary.tick == 1221 and oracle.summary.end_tick == 1221 and oracle.summary.clock_ms == 122050 and oracle.summary.end_ms == 122050 and oracle.summary.tick < b.tick and b.tick < natural.input.max_ticks and natural.input.max_ticks == 18000 and oracle.events[-1].kind == "battle_end" and oracle.events.any(func(e): return e.kind == "rejected" and e.value == "no_selection" and e.tick == 0) and oracle.log == [expected_a]
    var name := "prefix_then_terminal_unconsumed"
    cases.append(name)
    print("CASE_START " + name)
    var c := create(natural)
    ck(name,1,c.ok)
    ck(name,2,precondition)
    var o: OperationPrivateState = c.owner
    var result: Dictionary = Replay._play(o,natural.input.policy,natural.input.max_ticks,[a,b])
    ck(name,3,result == Adapter.fail("replay_unconsumed_command","commands[1].tick"))
    var packet := o.capture_completed()
    ck(name,4,packet.ok and packet.packet.view.sim.command_log == [expected_a])
    ck(name,5,packet.ok and packet.packet.view.sim._queue.is_empty())
    var sm := o.summary()
    ck(name,6,sm.ok and sm.summary.over and sm.summary.tick == oracle.summary.tick and sm.summary.end_tick == oracle.summary.end_tick and sm.summary.clock_ms == oracle.summary.clock_ms and sm.summary.end_ms == oracle.summary.end_ms)
    var drained := o.drain_events()
    ck(name,7,drained.ok and drained.events.is_empty())
    saved_log = packet.packet.view.sim.command_log.duplicate(true)
    saved_summary = sm.summary.duplicate(true)
    o.close()
    ck(name,8,o.summary() == Adapter.fail("unprepared_owner","owner"))
    print("CASE_END " + name)
    name = "invalid_late_prevalidates_all"
    cases.append(name)
    print("CASE_START " + name)
    c = create(natural)
    ck(name,1,c.ok)
    o = c.owner
    var initial := o.capture_completed()
    var initial_summary := o.summary()
    ck(name,2,initial.ok and initial_summary.ok)
    result = Replay._play(o,natural.input.policy,natural.input.max_ticks,[a,invalid])
    ck(name,3,result == Adapter.fail("unsupported_replay_command","commands[1].kind"))
    packet = o.capture_completed()
    sm = o.summary()
    ck(name,4,packet.ok and sm.ok)
    ck(name,5,sm.summary.tick == initial_summary.summary.tick and sm.summary.clock_ms == initial_summary.summary.clock_ms)
    ck(name,6,packet.packet.view.sim.command_log == initial.packet.view.sim.command_log and packet.packet.view.sim.command_log.is_empty())
    ck(name,7,packet.packet.view.sim._queue == initial.packet.view.sim._queue and packet.packet.view.sim._queue.is_empty())
    var events_same: bool = packet.packet.view.sim._events == initial.packet.view.sim._events
    o.close()
    ck(name,8,events_same and o.summary() == Adapter.fail("unprepared_owner","owner"))
    print("CASE_END " + name)
    name = "prefix_only_control"
    cases.append(name)
    print("CASE_START " + name)
    c = create(natural)
    ck(name,1,c.ok)
    ck(name,2,precondition)
    o = c.owner
    result = Replay._play(o,natural.input.policy,natural.input.max_ticks,[a])
    ck(name,3,result.ok)
    ck(name,4,result.commands_consumed == 1)
    ck(name,5,var_to_bytes(result.summary) == var_to_bytes(oracle.summary))
    ck(name,6,var_to_bytes(result.events) == var_to_bytes(oracle.events) and result.events[-1].kind == "battle_end")
    packet = o.capture_completed()
    ck(name,7,packet.ok and packet.packet.view.sim.command_log == [expected_a] and packet.packet.view.sim._queue.is_empty())
    var same: bool = packet.packet.view.sim.command_log == saved_log and result.summary == saved_summary
    o.close()
    ck(name,8,same and o.summary() == Adapter.fail("unprepared_owner","owner"))
    print("CASE_END " + name)
    name = "helper_close_error"
    cases.append(name)
    print("CASE_START " + name)
    c = create(natural)
    ck(name,1,c.ok)
    o = c.owner
    result = Replay._play_and_close(c,[a,b])
    ck(name,2,result == Adapter.fail("replay_unconsumed_command","commands[1].tick"))
    ck(name,3,result.ok == false)
    ck(name,4,result.error == "replay_unconsumed_command")
    ck(name,5,result.path == "commands[1].tick")
    ck(name,6,not result.has("summary") and not result.has("events") and not result.has("meta"))
    ck(name,7,o.summary() == Adapter.fail("unprepared_owner","owner"))
    ck(name,8,o._sim == null)
    print("CASE_END " + name)
    var ok: bool = failed == 0 and ids.size() == 32 and cases.size() == 4
    print("PROBE_RESULT " + JSON.stringify({"ok":ok,"checks":ids.size(),"ids":ids,"cases":cases,"failed":failed,"engine_pid":OS.get_process_id(),"engine_path":OS.get_executable_path()}))
    quit(0 if ok else 1)

