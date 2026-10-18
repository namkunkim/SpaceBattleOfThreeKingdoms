extends RefCounted

# 문서 안의 명시적인 설정 블록만 읽는다. 설명 문장은 실행하지 않는다.
const DOCUMENT_PATH := "res://data/fleet-role-layout.md"
const FENCE := "```fleet-role-layout"
const DEFAULT_CONFIG := {
	"version": 1,
	"order": ["SHP-05", "SHP-01", "SHP-06", "SHP-07", "SHP-08", "SHP-04", "SHP-02", "SHP-03"],
	"targets": {
		"SHP-01": [0.32, 0.18], "SHP-02": [0.25, 0.35],
		"SHP-03": [0.45, 0.65], "SHP-04": [0.90, 0.30],
		"SHP-05": [0.08, 0.05], "SHP-06": [0.58, 0.48],
		"SHP-07": [0.55, 1.00], "SHP-08": [1.00, 0.85],
	}
}

static func load_config(path := DOCUMENT_PATH) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var config := parse_document(file.get_as_text()) if file != null else {}
	if config.is_empty():
		push_warning("함종 배치 문서를 읽을 수 없거나 설정이 잘못되어 기본 배치를 사용합니다: " + path)
		config = DEFAULT_CONFIG.duplicate(true)
		config["source"] = "built-in fallback"
	else:
		config["source"] = path
	return config

static func parse_document(markdown: String) -> Dictionary:
	var start := markdown.find(FENCE)
	if start < 0 or markdown.find(FENCE, start + FENCE.length()) >= 0:
		return {}
	start += FENCE.length()
	var end := markdown.find("```", start)
	if end < 0:
		return {}
	var json := JSON.new()
	if json.parse(markdown.substr(start, end - start).strip_edges()) != OK:
		return {}
	var data: Variant = json.data
	if not data is Dictionary or data.get("version") != 1:
		return {}
	var order: Variant = data.get("order")
	var targets: Variant = data.get("targets")
	if not order is Array or not targets is Dictionary or order.size() != 8 or targets.size() != 8:
		return {}
	var seen := {}
	for id in order:
		if not id is String or not DEFAULT_CONFIG.targets.has(id) or seen.has(id):
			return {}
		seen[id] = true
		var point: Variant = targets.get(id)
		if not point is Array or point.size() != 2:
			return {}
		for value in point:
			if (not value is float and not value is int) or not is_finite(float(value)) or value < 0.0 or value > 1.0:
				return {}
	return data
