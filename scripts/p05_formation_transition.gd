extends RefCounted
## Scoped no-loss, fixed-heading formation sweep. Points use tactical units.
## Each half-extent describes the centered renderer hull quad without its trail.

static func validate(rows: Array, radius: float) -> Dictionary:
	if rows.is_empty() or not is_finite(radius) or radius <= 0.0:
		return {"ok": false, "error": "invalid_formation"}
	var identities := {}
	for row in rows:
		if not row is Dictionary or not row.get("id") is String or row.id.is_empty() or identities.has(row.id) \
				or not _finite_point(row.get("from")) or not _finite_point(row.get("to")) \
				or not _finite_point(row.get("half")) or row.half.x <= 0.0 or row.half.y <= 0.0:
			return {"ok": false, "error": "invalid_ship"}
		identities[row.id] = true
		for endpoint: String in ["from", "to"]:
			var corner := Vector2(absf(row[endpoint].x), absf(row[endpoint].y)) + Vector2(row.half)
			if corner.length_squared() > radius * radius:
				return {"ok": false, "error": "outer_radius", "ship": row.id, "endpoint": endpoint,
					"required_radius": corner.length()}
	for i in rows.size():
		for j in range(i + 1, rows.size()):
			var a: Dictionary = rows[i]
			var b: Dictionary = rows[j]
			var overlap := _overlap(a.from - b.from, a.to - b.to, a.half + b.half)
			if overlap != Vector2.ZERO:
				return {"ok": false, "error": "swept_overlap", "ships": [a.id, b.id],
					"fraction": (overlap.x + overlap.y) * 0.5}
	return {"ok": true}


static func _finite_point(value: Variant) -> bool:
	return value is Vector2 and value.is_finite()


# Open slabs represent interior overlap. A single time of edge/corner contact
# or a trajectory along an edge does not intersect both open slabs.
static func _overlap(from: Vector2, to: Vector2, limit: Vector2) -> Vector2:
	var velocity := to - from
	var enter := 0.0
	var leave := 1.0
	for axis in 2:
		if velocity[axis] == 0.0:
			if absf(from[axis]) >= limit[axis]:
				return Vector2.ZERO
			continue
		var start := (-limit[axis] - from[axis]) / velocity[axis]
		var end := (limit[axis] - from[axis]) / velocity[axis]
		enter = maxf(enter, minf(start, end))
		leave = minf(leave, maxf(start, end))
		if enter >= leave:
			return Vector2.ZERO
	return Vector2(enter, leave)
