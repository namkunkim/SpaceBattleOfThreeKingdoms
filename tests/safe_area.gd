extends SceneTree

# 안전 영역 보정 검증(헤드리스). 순수 계산(창·안전 영역 → 화면 단위)과 전투 HUD에 실제로 적용되는지 본다.

var fails := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", msg)

func _run() -> void:
	# 태블릿 가로(2560×1600): 왼쪽 카메라 구멍 90px, 아래 내비게이션 바 48px
	var win := Rect2i(0, 0, 2560, 1600)
	var safe := Rect2i(90, 0, 2470, 1552)
	var px := SafeArea.window_insets_px(safe, win)
	_check(px == Vector4(90, 0, 0, 48), "창 가장자리별 가려지는 픽셀 %s" % px)
	# PC 창 모드: 창이 안전 영역 안에 있으면 0
	var pc := SafeArea.window_insets_px(Rect2i(0, 0, 1920, 1040), Rect2i(100, 100, 1600, 900))
	_check(pc == Vector4.ZERO, "PC 창 모드는 0: %s" % pc)
	# 안전 영역을 못 읽으면(크기 0) 0
	_check(SafeArea.window_insets_px(Rect2i(), win) == Vector4.ZERO, "빈 안전 영역은 0")
	# 픽셀 → 화면 단위(2560×1600은 1600×1000 단위, 1.6배)
	var u := SafeArea.to_units(px, 1.6, Vector2(2560, 1600))
	_check(is_equal_approx(u.x, 56.25) and is_equal_approx(u.w, 30.0), "화면 단위 변환 %s" % u)
	# 터무니없는 값(창의 절반 이상)은 버린다
	_check(SafeArea.to_units(Vector4(1500, 0, 0, 0), 1.6, Vector2(2560, 1600)) == Vector4.ZERO, "잘못된 보고는 버림")
	# 실제 HUD 적용
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 4:
		await process_frame
	var deck = battle.presentation.hud
	var fitter: SafeArea = deck.get_node_or_null("SafeArea")
	_check(fitter != null, "HUD에 SafeArea가 붙어 있다")
	if fitter:
		_check(deck.hud.offset_left == 0.0 and deck.hud.offset_bottom == 0.0, "보정 없음: 오프셋 0")
		# 헤드리스 창은 작으므로 창 크기에 비례한 값(왼쪽 3.5%, 아래 3%)을 쓴다
		var w := float(root.size.x)
		var h := float(root.size.y)
		SafeArea.override_px = Vector4(w * 0.035, 0, 0, h * 0.03)
		fitter.refresh()
		var ppu := w / root.get_visible_rect().size.x
		_check(is_equal_approx(deck.hud.offset_left, w * 0.035 / ppu), "HUD 왼쪽이 안전 영역만큼 들어간다 %s" % deck.hud.offset_left)
		_check(is_equal_approx(deck.hud.offset_bottom, -h * 0.03 / ppu), "HUD 아래가 안전 영역만큼 올라간다 %s" % deck.hud.offset_bottom)
		_check(deck.hud.offset_left > 0.0 and deck.hud.offset_bottom < 0.0, "오프셋이 실제로 0이 아니다")
		SafeArea.override_px = null
		fitter.refresh()
		_check(deck.hud.offset_left == 0.0, "보정을 풀면 원위치")
	print("SAFE_AREA_PASS" if fails == 0 else "SAFE_AREA_FAIL %d" % fails)
	quit(0 if fails == 0 else 1)
