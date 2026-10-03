class_name SafeArea
extends Node

# 안전 영역(노치·카메라 구멍·내비게이션 바) 보정. 안드로이드 태블릿에서 HUD가 가려지지 않게 한다.
# 대상 Control(전투 HUD)의 가장자리를 안전 영역만큼 안쪽으로 민다. 배경·전장은 화면 끝까지 그대로다.
# PC 창 모드에서는 창이 OS 안전 영역 안에 있으면 보정이 0이다.
# 확인용 덮어쓰기: 환경변수 SBTK_SAFE_INSETS="왼,위,오른,아래"(화면 픽셀) 또는 override_px.

const ENV_NAME := "SBTK_SAFE_INSETS"
const POLL_SEC := 1.0

static var override_px: Variant = null   # Vector4(왼, 위, 오른, 아래) 화면 픽셀

var target: Control
var insets := Vector4.ZERO   # 화면 단위(캔버스 좌표)
var _acc := 0.0

# 화면 좌표의 안전 영역과 창 사각형에서 창 가장자리별 가려지는 픽셀을 구한다.
static func window_insets_px(safe: Rect2i, win_rect: Rect2i) -> Vector4:
	if safe.size.x <= 0 or safe.size.y <= 0:
		return Vector4.ZERO
	return Vector4(
		maxf(0.0, safe.position.x - win_rect.position.x),
		maxf(0.0, safe.position.y - win_rect.position.y),
		maxf(0.0, win_rect.end.x - safe.end.x),
		maxf(0.0, win_rect.end.y - safe.end.y))

# 픽셀 → 화면 단위. 한 변이 창 크기의 절반을 넘는 값은 잘못된 보고로 보고 버린다.
static func to_units(px: Vector4, px_per_unit: float, win_px: Vector2) -> Vector4:
	var k := 1.0 / maxf(0.001, px_per_unit)
	var v := px
	if v.x + v.z >= win_px.x * 0.5 or v.y + v.w >= win_px.y * 0.5:
		return Vector4.ZERO
	return v * k

static func _env_override() -> Variant:
	var s := OS.get_environment(ENV_NAME)
	if s == "":
		return null
	var p := s.split(",")
	if p.size() != 4:
		return null
	return Vector4(float(p[0]), float(p[1]), float(p[2]), float(p[3]))

static func current_px(win: Window) -> Vector4:
	if override_px is Vector4:
		return override_px
	var env: Variant = _env_override()
	if env is Vector4:
		return env
	if DisplayServer.get_name() == "headless":
		return Vector4.ZERO
	var safe := DisplayServer.get_display_safe_area()
	return window_insets_px(safe, Rect2i(win.position, win.size))

func setup(c: Control) -> void:
	target = c
	get_window().size_changed.connect(refresh)
	refresh()

func refresh() -> void:
	if target == null or not is_instance_valid(target):
		return
	var win := get_window()
	var vis := win.get_visible_rect().size
	var ppu := float(win.size.x) / maxf(1.0, vis.x)
	insets = to_units(current_px(win), ppu, Vector2(win.size))
	target.offset_left = insets.x
	target.offset_top = insets.y
	target.offset_right = -insets.z
	target.offset_bottom = -insets.w

# 안전 영역은 회전·내비게이션 바 모드가 바뀌면 달라진다. 이벤트가 없는 플랫폼을 위해 가끔 다시 읽는다.
func _process(delta: float) -> void:
	_acc += delta
	if _acc >= POLL_SEC:
		_acc = 0.0
		refresh()
