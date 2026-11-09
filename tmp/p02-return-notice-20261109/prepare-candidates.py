from pathlib import Path
import difflib

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]

edits = {
    "scripts/world_link.gd": [
        ("func back_to_world(o: BattleOutcome) -> void:", "func back_to_world(o: BattleOutcome) -> Error:"),
        ('\t\tpush_warning("WORLD_RETURN_REJECTED error=%d" % error)', '\t\tpush_warning("WORLD_RETURN_REJECTED error=%d" % error)\n\treturn error'),
    ],
    "scripts/FleetBattle3D.gd": [
        ("\tif initial:\n\t\tvar exit := Button.new()", """\tif initial:
\t\tvar return_notice: Label
\t\tif in_world:
\t\t\tconst screens := preload("res://hud/ui_kit/deck_screens.gd")
\t\t\treturn_notice = screens.world_return_notice()
\t\t\tvar notice_slot := Control.new()
\t\t\tnotice_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
\t\t\tnotice_slot.custom_minimum_size.y = 42
\t\t\tcontent.add_child(notice_slot)
\t\t\tnotice_slot.add_child(return_notice)
\t\t\treturn_notice.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
\t\tvar exit := Button.new()"""),
        ('\t\t\tvar link := get_node("/root/WorldLink")\n\t\t\texit.pressed.connect(func(): link.back_to_world(null))', """\t\t\texit.pressed.connect(func():
\t\t\t\tif back_to_world() != OK:
\t\t\t\t\treturn_notice.show()
\t\t\t)"""),
        ("""func back_to_world() -> void:
\tvar link := get_node_or_null("/root/WorldLink")
\tif link == null:
\t\treturn
\tlink.back_to_world(BattleOutcome.from_sim(sim, link.brief) if sim.st.over else null)""", """func back_to_world() -> Error:
\tvar link := get_node_or_null("/root/WorldLink")
\tif link == null:
\t\treturn ERR_UNAVAILABLE
\tvar outcome := BattleOutcome.from_sim(sim, link.brief) if sim != null and sim.st.over else null
\treturn link.back_to_world(outcome)"""),
    ],
    "hud/ui_kit/command_deck.gd": [
        ("""func to_title() -> void:
\tif battle.has_method("routed") and battle.routed():
\t\tbattle.back_to_world()
\t\treturn""", """func to_title(return_notice: Label = null) -> void:
\tif battle.has_method("routed") and battle.routed():
\t\tvar error: Error = battle.back_to_world()
\t\tif error != OK and return_notice != null:
\t\t\treturn_notice.show()
\t\treturn"""),
    ],
    "hud/ui_kit/deck_screens.gd": [
        ('static func build_all(deck: Control) -> Dictionary:', """const WORLD_RETURN_NOTICE := "천하로 돌아가지 못했습니다. 다시 눌러 주세요."

static func world_return_notice() -> Label:
\tvar notice := UiTheme.label(WORLD_RETURN_NOTICE, "Body", 16, UiTheme.WARN)
\tnotice.name = "WorldReturnNotice"
\tnotice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
\tnotice.mouse_filter = Control.MOUSE_FILTER_IGNORE
\tnotice.hide()
\treturn notice

static func build_all(deck: Control) -> Dictionary:"""),
        ('"pause": PauseScreen.new(deck)', '"pause": PauseScreen.new(deck, world_return_notice())'),
        ('"result": ResultScreen.new(deck)', '"result": ResultScreen.new(deck, world_return_notice())'),
        ('class PauseScreen extends Control:\n\tvar deck: Control\n\tvar title_btn: Button\n\tfunc _init(d: Control) -> void:', 'class PauseScreen extends Control:\n\tvar deck: Control\n\tvar title_btn: Button\n\tvar return_notice: Label\n\tfunc _init(d: Control, notice: Label) -> void:'),
        ('\t\tvar specs := [["계속"', """\t\treturn_notice = notice
\t\treturn_notice.position = Vector2(36, 436)
\t\treturn_notice.size = Vector2(344, 32)
\t\tp.add_child(return_notice)
\t\tvar specs := [["계속" """.rstrip()),
        ('["타이틀로", func(): deck.to_title()]', '["타이틀로", func(): deck.to_title(return_notice)]'),
        ('\tfunc on_show() -> void:\n\t\tif title_btn:', '\tfunc on_show() -> void:\n\t\treturn_notice.hide()\n\t\tif title_btn:'),
        ('class ResultScreen extends Control:\n\tvar deck: Control\n\tvar t := 0.0\n\tvar title_btn: Button\n\tfunc _init(d: Control) -> void:', 'class ResultScreen extends Control:\n\tvar deck: Control\n\tvar t := 0.0\n\tvar title_btn: Button\n\tvar return_notice: Label\n\tfunc _init(d: Control, notice: Label) -> void:'),
        ('\t\ttitle.pressed.connect(func(): deck.to_title())', '\t\ttitle.pressed.connect(func(): deck.to_title(return_notice))'),
        ('\t\thb.add_child(again)\n\tfunc _process', """\t\thb.add_child(again)
\t\treturn_notice = notice
\t\treturn_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\t\tadd_child(return_notice)
\t\treturn_notice.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
\t\treturn_notice.offset_left = -230
\t\treturn_notice.offset_right = 230
\t\treturn_notice.offset_top = -48
\t\treturn_notice.offset_bottom = -8
\tfunc _process"""),
        ('\t\tt = 0.0\n\t\ttitle_btn.text = deck.title_label()', '\t\tt = 0.0\n\t\treturn_notice.hide()\n\t\ttitle_btn.text = deck.title_label()'),
    ],
}

patch = []
for rel, changes in edits.items():
    raw = (ROOT / rel).read_bytes()
    before = raw.decode("utf-8")
    newline = "\r\n" if "\r\n" in before else "\n"
    after = before
    for old, new in changes:
        old, new = (part.replace("\n", newline) for part in (old, new))
        if after.count(old) != 1:
            raise ValueError((rel, old))
        after = after.replace(old, new, 1)
    name = Path(rel).name
    (BASE / (name + ".before.txt")).write_bytes(raw)
    (BASE / (name + ".candidate.txt")).write_bytes(after.encode("utf-8"))
    patch.extend(difflib.unified_diff(before.splitlines(keepends=True), after.splitlines(keepends=True),
                                      fromfile="a/" + rel, tofile="b/" + rel))
(BASE / "candidate.diff").write_bytes("".join(patch).encode("utf-8"))


