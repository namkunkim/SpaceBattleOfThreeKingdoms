class_name TouchMetrics
extends RefCounted

# 터치 목표 크기 계산(제안서 v0.2 §7.2: 약 9mm 또는 48dp 이상).
# 화면 단위(1600×900 기준, stretch canvas_items·expand) → 실제 픽셀 → dp(160dpi 기준) 순으로 바꾼다.

const BASE := Vector2(1600, 900)
const MIN_DP := 48.0

# 기준 기기: [이름, 화면 픽셀(가로), dpi]
const DEVICES := [
	["폰 6.1\" (2400×1080, 400dpi)", Vector2(2400, 1080), 400.0],
	["태블릿 11\" (2388×1668, 264dpi)", Vector2(2388, 1668), 264.0],
	["PC 24\" (1920×1080, 92dpi)", Vector2(1920, 1080), 92.0],
]

# 화면 단위 1이 몇 dp인가
static func dp_per_unit(screen_px: Vector2, dpi: float, ui_scale := 1.0) -> float:
	var px_per_unit := minf(screen_px.x / BASE.x, screen_px.y / BASE.y) * ui_scale
	return px_per_unit * 160.0 / maxf(1.0, dpi)

# 지금 실행 중인 화면에서의 값(모바일 실기기에서 의미가 있다)
static func current_dp_per_unit(win: Window) -> float:
	var dpi := float(DisplayServer.screen_get_dpi())
	return dp_per_unit(Vector2(win.size), dpi, win.content_scale_factor)

# 기준 dp를 넘기려면 필요한 UI 크기 배율
static func scale_for(units: float, screen_px: Vector2, dpi: float, dp := MIN_DP) -> float:
	return dp / maxf(0.001, units * dp_per_unit(screen_px, dpi))

# HUD가 겹치지 않는 최소 화면(단위). 상단 전황 820 + 우측 시스템·좌측 교신을 합친 폭.
const FIT_MIN := Vector2(1500, 680)

# 모바일에서 처음 실행할 때의 UI 크기: 명령 버튼(가장 자주 누르는 목표)이 48dp에 닿는 가장 작은 배율.
# 단, HUD가 화면에 다 들어가는 배율까지만 키운다(4:3 태블릿은 100%에 머문다).
static func pick_ui_scale(screen_px: Vector2, dpi: float, scales: Array, cmd_units := 78.0) -> float:
	var best := 1.0
	for s in scales:
		if s < 1.0:
			continue
		var canvas: Vector2 = screen_px / (minf(screen_px.x / BASE.x, screen_px.y / BASE.y) * s)
		if canvas.x < FIT_MIN.x or canvas.y < FIT_MIN.y:
			break
		best = s
		if cmd_units * dp_per_unit(screen_px, dpi, s) >= MIN_DP:
			break
	return best

static func default_ui_scale(scales: Array) -> float:
	if not OS.has_feature("mobile"):
		return 1.0
	var sc := DisplayServer.screen_get_size()
	var px := Vector2(maxi(sc.x, sc.y), mini(sc.x, sc.y))   # 가로 화면 기준
	return pick_ui_scale(px, float(DisplayServer.screen_get_dpi()), scales)
