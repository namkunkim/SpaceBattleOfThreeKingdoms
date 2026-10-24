extends Translation

# Independent resource: no reference back to GameLocale during engine shutdown.
const CATALOG = preload("res://data/i18n/messages.json")
var column := 0
var audit_enabled := false
var untranslated := {}

func _get_message(source: StringName, _context: StringName) -> StringName:
	if column < 0:
		return source
	var result := lookup(String(source))
	if audit_enabled and _has_hangul(String(source)) and (result == "" or _has_hangul(result)):
		untranslated[String(source)] = result
	return StringName(result)

var _patterns: Array = []
var _cache := {}
var _fragments := {}

func lookup(source: String, depth := 0) -> String:
	source = source.replace("\r\n", "\n")
	if CATALOG.data.has(source):
		return CATALOG.data[source][column]
	if depth > 16 or not _has_hangul(source):
		return ""
	var cache_key := str(column) + ":" + source
	if _cache.has(cache_key):
		return _cache[cache_key]
	if _patterns.is_empty():
		for key: String in CATALOG.data:
			if "%" not in key:
				# Short standalone captions must not replace syllables inside words.
				if key.length() > 1 and _has_hangul(key):
					var initial := key.left(1)
					if not _fragments.has(initial):
						_fragments[initial] = []
					_fragments[initial].append(key)
				continue
			var format_re := RegEx.new()
			format_re.compile("%[-+0-9.]*[dsf]")
			var matches := format_re.search_all(key)
			if matches.is_empty():
				continue
			var pattern := "(?s)^"
			var offset := 0
			for m in matches:
				pattern += _escape(key.substr(offset, m.get_start() - offset)).replace("%%", "%")
				pattern += "(.*?)" if m.get_string().ends_with("s") else "([-+−]?[0-9]+(?:\\.[0-9]+)?)"
				offset = m.get_end()
			pattern += _escape(key.substr(offset)).replace("%%", "%") + "$"
			var regex := RegEx.new()
			if regex.compile(pattern) == OK:
				_patterns.append([regex, key, format_re.sub(key, "", true).length()])
		_patterns.sort_custom(func(a, b): return a[2] > b[2])
		for initial in _fragments:
			_fragments[initial].sort_custom(func(a, b): return a.length() > b.length())
	for entry in _patterns:
		var matched: RegExMatch = entry[0].search(source)
		if not matched:
			continue
		var translated: String = CATALOG.data[entry[1]][column]
		var fmt := RegEx.new()
		fmt.compile("%[-+0-9.]*[dsf]")
		var placeholders := fmt.search_all(translated)
		if placeholders.size() != matched.get_group_count():
			continue
		for i in range(placeholders.size() - 1, -1, -1):
			var p: RegExMatch = placeholders[i]
			var value := matched.get_string(i + 1)
			var nested := lookup(value, depth + 1) if value != source else ""
			translated = translated.substr(0, p.get_start()) + (nested if nested != "" else value) + translated.substr(p.get_end())
		translated = translated.replace("%%", "%")
		# A broad %s pattern must not hide an untranslated nested caption.
		if _has_hangul(translated):
			continue
		# Bound the cache: ship counts and battle timers change continuously.
		if _cache.size() >= 2048:
			_cache.clear()
		_cache[cache_key] = translated
		return translated
	# UI strings often join independent captions with separators or line breaks.
	for separator in ["\n", " · ", " — ", "  ", " / ", " → "]:
		if separator not in source:
			continue
		var parts := source.split(separator)
		var changed := false
		for i in parts.size():
			var part := lookup(parts[i], depth + 1)
			if part != "":
				parts[i] = part
				changed = true
		if changed:
			var result: String = separator.join(parts)
			if not _has_hangul(result):
				_cache[cache_key] = result
				return result
	# Composed tooltips also include punctuation, BBCode and adjacent captions.
	# Resolve literal fragments without changing the source stored on controls.
	var result := ""
	var cursor := 0
	var changed := false
	while cursor < source.length():
		var found := false
		if source.substr(cursor, 1) == "(":
			var end := source.find(")", cursor + 1)
			if end > cursor and end - cursor + 1 < source.length():
				var bracket := source.substr(cursor, end - cursor + 1)
				var inner := lookup(bracket, depth + 1)
				if inner != "" and not _has_hangul(inner):
					result += inner
					cursor = end + 1
					changed = true
					continue
		for key: String in _fragments.get(source.substr(cursor, 1), []):
			if source.substr(cursor, key.length()) == key:
				result += str(CATALOG.data[key][column])
				cursor += key.length()
				found = true
				changed = true
				break
		if not found:
			result += source.substr(cursor, 1)
			cursor += 1
	if changed:
		if _cache.size() >= 2048:
			_cache.clear()
		if not _has_hangul(result):
			_cache[cache_key] = result
		return result
	if _cache.size() >= 2048:
		_cache.clear()
	if depth == 0:
		_cache[cache_key] = ""
	return ""

static func _has_hangul(value: String) -> bool:
	for index in value.length():
		var code := value.unicode_at(index)
		if code >= 0xac00 and code <= 0xd7a3:
			return true
	return false

func _escape(value: String) -> String:
	var result := ""
	for character in value:
		if character in "\\.^$|?*+()[]{}":
			result += "\\"
		result += character
	return result
