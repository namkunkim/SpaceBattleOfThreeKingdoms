class_name GameLocale
extends RefCounted

const CODES := ["ko", "en", "zh_CN", "ja"]
const NAMES := ["한국어", "English", "简体中文", "日本語"]
const CATALOG_SCRIPT = preload("res://hud/ui_kit/catalog_translation.gd")
const CATALOG = preload("res://data/i18n/messages.json")
static var current := "ko"
static var _registered := false
static var _catalogs: Array[Translation] = []

static func normalize(code: String) -> String:
	return code if code in CODES else "ko"

static func set_language(code: String) -> void:
	if not _registered:
		_registered = true
		for i in CODES.size():
			var catalog := CATALOG_SCRIPT.new()
			catalog.column = i - 1
			catalog.set_locale(CODES[i])
			TranslationServer.add_translation(catalog)
			_catalogs.append(catalog)
		var main_loop := Engine.get_main_loop() as SceneTree
		if main_loop:
			main_loop.root.tree_exiting.connect(shutdown, CONNECT_ONE_SHOT)
	current = normalize(code)
	TranslationServer.set_locale(current)
	# Custom painted panels need repainting in addition to native translation notifications.
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		_redraw(tree.root)

static func shutdown() -> void:
	# Stop scripted translation callbacks before GDScript's static state is released.
	for catalog in _catalogs:
		TranslationServer.remove_translation(catalog)
	_catalogs.clear()
	_registered = false

static func _redraw(node: Node) -> void:
	if node is CanvasItem:
		(node as CanvasItem).queue_redraw()
	for child in node.get_children():
		_redraw(child)

static func text(source: String) -> String:
	if current == "ko":
		return source
	return TranslationServer.translate(source)
