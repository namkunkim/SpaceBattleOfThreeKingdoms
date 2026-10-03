class_name ScreenKit
extends RefCounted

# 화면 공용 부품.

const W := preload("res://hud/ui_kit/deck_widgets.gd")

static func full(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP

static func centered(parent: Control, sz: Vector2, style: StyleBox) -> Control:
	var p := W.DrawPanel.new(Callable(), style)
	parent.add_child(p)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -sz.x * 0.5
	p.offset_top = -sz.y * 0.5
	p.offset_right = sz.x * 0.5
	p.offset_bottom = sz.y * 0.5
	return p

static func menu_button(text: String, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = "PrimaryButton" if primary else "MenuButton2"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT if not primary else HORIZONTAL_ALIGNMENT_CENTER
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

static func rule(c: Control, a: Vector2, b: Vector2) -> void:
	c.draw_line(a, b, Color(UiTheme.GOLD, 0.35), 1.0)
	UiDraw.diamond(c, (a + b) * 0.5, 3.5, UiTheme.GOLD)

