extends RefCounted
# Validate every field consumed by entry_map before publishing render state.
static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and absf(float(value)) <= 3.4028234e38

static func _pair(value: Variant) -> bool:
	return value is Array and value.size() == 2 and _number(value[0]) and _number(value[1])

static func _extent(value: Variant) -> bool:
	return _pair(value) and Vector2(value[0], value[1]).x > 0.0 and Vector2(value[0], value[1]).y > 0.0

static func _position(value: Variant, extent: Array) -> bool:
	return _pair(value) and value[0] >= 0 and value[1] >= 0 and value[0] <= extent[0] and value[1] <= extent[1]

static func _name(value: Variant) -> bool:
	return value is String and not value.strip_edges().is_empty()

static func validate(value: Variant, detailed: bool) -> String:
	if not value is Dictionary: return "root"
	if detailed: return _operation(value)
	return _atlas(value)

static func _operation(value: Dictionary) -> String:
	var space: Variant = value.get("space")
	if not space is Dictionary: return "space"
	var extent: Variant = space.get("size")
	if not _extent(extent): return "space.size"
	var nodes: Variant = space.get("nodes")
	if not nodes is Dictionary: return "space.nodes"
	for id: String in ["E", "J", "A", "C", "R"]:
		if not nodes.has(id): return "space.nodes." + id
	for id: Variant in nodes:
		if not _name(id): return "space.nodes.key"
		if not _position(nodes[id], extent): return "space.nodes." + id
	var routes: Variant = space.get("routes")
	if not routes is Dictionary: return "space.routes"
	var front: Variant = routes.get("front")
	if not front is Dictionary: return "space.routes.front"
	var route: Variant = front.get("nodes")
	if not route is Array or route.size() < 2: return "space.routes.front.nodes"
	var distinct := {}
	for id: Variant in route:
		if not _name(id) or not nodes.has(id): return "space.routes.front.nodes.reference"
		distinct[id] = true
	if distinct.size() < 2: return "space.routes.front.nodes.distinct"
	return ""

static func _atlas(value: Dictionary) -> String:
	if not _number(value.get("width")): return "width"
	if not _number(value.get("height")): return "height"
	var extent := [value.width, value.height]
	if not _extent(extent): return "width/height"
	for key: String in ["points", "regions", "routes"]:
		if not value.get(key) is Array or value[key].is_empty(): return key
	for point: Variant in value.points:
		if not point is Dictionary: return "points.item"
		if not _position(point.get("position"), extent): return "points.position"
		if not _name(point.get("kind")): return "points.kind"
	var active_regions := 0
	for region: Variant in value.regions:
		if not region is Dictionary: return "regions.item"
		if not _position(region.get("position"), extent): return "regions.position"
		if not _name(region.get("name")): return "regions.name"
		if region.name == "형초": active_regions += 1
	if active_regions != 1: return "regions.active"
	for route: Variant in value.routes:
		if not route is Dictionary: return "routes.item"
		var points: Variant = route.get("points")
		if not points is Array or points.size() < 2: return "routes.points"
		for point: Variant in points:
			if not _position(point, extent): return "routes.points.position"
	return ""
