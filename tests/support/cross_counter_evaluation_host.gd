extends Control
## Private projection-only evaluator host. It never accesses BattleSim or public routing.
var operation_owner: RefCounted
var dispatch: Callable
var model: Dictionary = {}
var paused := true
var last_result: Dictionary = {}
var buttons: Dictionary = {}
var _status: Label
var _clock: Label
var _pending: Label
var _x: SpinBox
var _y: SpinBox
const FIELD := Rect2(36, 154, 1040, 703.5294)
const WORLD := Vector2(1700, 1150)

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _label("Cross Counter  /  isolated evaluation", Vector2(36, 24), 30)
    _label("Fixture roster · fleet-centre projection · no campaign settlement", Vector2(36, 70), 18)
    _clock = _label("No checkpoint installed", Vector2(1140, 162), 22)
    _pending = _label("", Vector2(1140, 198), 18)
    var captions := {"begin": "Start / resume", "step": "Advance one tick (0.1 s)", "pause": "Pause",
        "stop": "Queue stop", "move": "Queue move", "save": "Save isolated checkpoint", "load": "Restore saved checkpoint"}
    var ys := {"begin": 248, "step": 298, "pause": 348, "stop": 398, "move": 508, "save": 568, "load": 618}
    for key in captions:
        var button := Button.new()
        button.text = captions[key]
        button.position = Vector2(1140, ys[key])
        button.size = Vector2(390, 42)
        button.pressed.connect(_activate.bind(key))
        buttons[key] = button
        add_child(button)
    _label("Move target  X / Y", Vector2(1140, 448), 16)
    _x = _coordinate(Vector2(1140, 473), 1700, 900)
    _y = _coordinate(Vector2(1340, 473), 1150, 500)
    _status = _label("Waiting for a validated authority record.", Vector2(1140, 686), 16)
    _status.size = Vector2(400, 130)
    _status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _label("Single-tick evaluation with an isolated save.\nNo public operation entry.", Vector2(1140, 810), 15)
    _sync_controls()

func _label(value: String, where: Vector2, font_size: int) -> Label:
    var label := Label.new()
    label.text = value
    label.position = where
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color("d8e4ed"))
    add_child(label)
    return label

func _coordinate(where: Vector2, maximum: float, initial: float) -> SpinBox:
    var spin := SpinBox.new()
    spin.position = where
    spin.size = Vector2(190, 30)
    spin.min_value = 0
    spin.max_value = maximum
    spin.value = initial
    add_child(spin)
    return spin

static func prepare_model(frame: Dictionary, diagnostic: Dictionary) -> Dictionary:
    var projection: Variant = frame.get("projection")
    if not projection is Dictionary or not projection.get("squadrons") is Array \
            or projection.squadrons.size() != 2 or frame.get("tick") != projection.get("tick") \
            or frame.get("clock_ms") != int(frame.get("tick", -1)) * 100 or projection.get("hz") != 10:
        return {"ok": false, "error": "invalid_evaluation_frame"}
    var fleets: Array[Dictionary] = []
    for row in projection.squadrons:
        if not row is Dictionary or not row.get("pos") is Vector2 or not row.pos.is_finite() \
                or typeof(row.get("id")) != TYPE_INT or row.get("side") not in [0, 1] \
                or not is_finite(float(row.get("heading", INF))) or typeof(row.get("ships_milli")) != TYPE_INT:
            return {"ok": false, "error": "invalid_evaluation_fleet"}
        fleets.append({"id": row.id, "side": row.side, "name": row.name, "pos": row.pos,
            "heading": row.heading, "ships_milli": row.ships_milli})
    if fleets[0].side == fleets[1].side: return {"ok": false, "error": "invalid_evaluation_sides"}
    return {"ok": true, "model": {"operation_id": diagnostic.operation_id, "tick": frame.tick,
        "clock_ms": frame.clock_ms, "fleets": fleets, "bootstrap_done": diagnostic.bootstrap_done,
        "pending_count": diagnostic.pending.size(), "history_batches": diagnostic.commands.size()}}

# The bridge calls this synchronous, non-failing swap only after preflight and guarded publish.
func install(next_owner: RefCounted, next_model: Dictionary) -> void:
    operation_owner = next_owner
    model = next_model.duplicate(true)
    paused = true
    _status.text = "Validated checkpoint installed."
    _sync_controls()
    queue_redraw()

func refresh() -> Dictionary:
    if operation_owner == null: return {"ok": false, "error": "host_has_no_owner"}
    var projection: Dictionary = operation_owner.read_projection()
    var diagnostic: Dictionary = operation_owner.capture_checkpoint()
    if not projection.ok or not diagnostic.ok: return {"ok": false, "error": "host_owner_unavailable"}
    var value: Dictionary = diagnostic.packet
    var next := prepare_model({"tick": value.tick, "clock_ms": value.clock_ms,
        "projection": projection.projection}, value)
    if not next.ok: return next
    model = next.model
    _sync_controls()
    queue_redraw()
    return {"ok": true}

func _activate(action: String) -> void:
    if action == "pause":
        paused = not paused
        last_result = {"ok": true, "paused": paused}
    else:
        var payload := {"point": Vector2(_x.value, _y.value)} if action == "move" else {}
        last_result = dispatch.call(action, payload)
        if last_result.ok and action == "begin": paused = false
        if last_result.ok and action != "load":
            var updated := refresh()
            if not updated.ok: last_result = updated
    _status.text = ("%s complete" % action) if last_result.ok else str(last_result.get("error", "action_failed"))
    _sync_controls()

func activate(action: String, point := Vector2(900, 500)) -> Dictionary:
    if not buttons.has(action): return {"ok": false, "error": "unknown_host_control"}
    if buttons[action].disabled: return {"ok": false, "error": "control_disabled"}
    _x.value = point.x
    _y.value = point.y
    last_result = {"ok": false, "error": "signal_not_delivered"}
    buttons[action].pressed.emit()
    return last_result.duplicate(true)

func snapshot() -> Dictionary:
    var controls := {}
    for key in buttons:
        controls[key] = {"disabled": buttons[key].disabled, "visible": buttons[key].is_visible_in_tree()}
    return {"model": model.duplicate(true), "paused": paused, "controls": controls,
        "viewport": get_viewport_rect().size, "status": _status.text,
        "installed_owner_live": operation_owner != null and operation_owner.summary().get("ok") == true}

func _sync_controls() -> void:
    if buttons.is_empty(): return
    for key in buttons: buttons[key].disabled = operation_owner == null
    var begun: bool = model.get("bootstrap_done", false)
    buttons.step.disabled = operation_owner == null or paused or not begun
    buttons.move.disabled = operation_owner == null or not begun
    buttons.stop.disabled = operation_owner == null or not begun
    buttons.pause.disabled = operation_owner == null or not begun
    buttons.pause.text = "Resume stepping" if paused else "Pause stepping"
    if not model.is_empty():
        _clock.text = "Tick %d  /  %.1f s" % [model.tick, model.clock_ms / 1000.0]
        _pending.text = "Pending %d  ·  History batches %d" % [model.pending_count, model.history_batches]

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("101923"))
    draw_rect(FIELD, Color("172c38"))
    for x in range(0, 1701, 100):
        var px := FIELD.position.x + x * FIELD.size.x / WORLD.x
        draw_line(Vector2(px, FIELD.position.y), Vector2(px, FIELD.end.y), Color("25414e"))
    for y in range(0, 1151, 100):
        var py := FIELD.position.y + y * FIELD.size.y / WORLD.y
        draw_line(Vector2(FIELD.position.x, py), Vector2(FIELD.end.x, py), Color("25414e"))
    draw_rect(FIELD, Color("597786"), false, 2)
    if model.is_empty(): return
    var font := get_theme_default_font()
    for fleet in model.fleets:
        var centre: Vector2 = FIELD.position + fleet.pos * FIELD.size / WORLD
        var direction := Vector2.RIGHT.rotated(fleet.heading)
        var normal := direction.orthogonal()
        var shape := PackedVector2Array([centre + direction * 20, centre - direction * 13 + normal * 10,
            centre - direction * 8, centre - direction * 13 - normal * 10])
        var color := Color("63c8e7") if fleet.side == 0 else Color("f5aa70")
        draw_colored_polygon(shape, color)
        draw_string(font, centre + Vector2(-35, 42), "%s  %.0f ships" % [fleet.name, fleet.ships_milli / 1000.0],
            HORIZONTAL_ALIGNMENT_LEFT, -1, 19, color)
        draw_string(font, centre + Vector2(-35, 64), "(%.1f, %.1f)" % [fleet.pos.x, fleet.pos.y],
            HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("b4c7d2"))
