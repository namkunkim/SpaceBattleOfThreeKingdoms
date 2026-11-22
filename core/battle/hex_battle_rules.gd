extends RefCounted

const RADIUS := 64.0
const WIDTH := RADIUS * 1.7320508075688772
const ROW_HEIGHT := RADIUS * 1.5

static func cell(point: Vector2) -> Vector2i:
	var r := point.y / ROW_HEIGHT
	var q := point.x / WIDTH - r * 0.5
	var s := -q - r
	var rq := roundi(q)
	var rr := roundi(r)
	var rs := roundi(s)
	var error_q := absf(rq - q)
	var error_r := absf(rr - r)
	var error_s := absf(rs - s)
	if error_q > error_r and error_q > error_s:
		rq = -rr - rs
	elif error_r > error_s:
		rr = -rq - rs
	return Vector2i(rq, rr)

static func center(coord: Vector2i) -> Vector2:
	return Vector2((coord.x + coord.y * 0.5) * WIDTH, coord.y * ROW_HEIGHT)

static func distance(a: Vector2, b: Vector2) -> int:
	return cell_distance(cell(a), cell(b))

static func cell_distance(a: Vector2i, b: Vector2i) -> int:
	var delta := a - b
	return maxi(maxi(absi(delta.x), absi(delta.y)), absi(delta.x + delta.y))

static func weapon_reach(category: String) -> int:
	# The RTS missile command maps to artillery. All other weapon categories use one cell.
	return 2 if category == "artillery" else 1
