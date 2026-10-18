extends SceneTree

# PoC 반영 C: 가시 범위(바깥 함선 + view_r), 정찰함 레이더(radar_r). 영역 안 적 함선이 하나라도 있으면 확인 접촉(Q107).
#  점수 탐지를 끈 상태(센서 0)로 가시 영역만 본다.

func _initialize() -> void:
	call_deferred("_run")

var _ok := true
func _check(c: bool, m: String) -> void:
	if not c:
		_ok = false
		print("FAIL: ", m)

func _sim(ally: Array, foe: Array) -> BattleSim:
	var full := SalvoFixture.combat()
	return SalvoFixture.sim(ally, foe, 1, "", func(cb):
		cb.detection = full.detection.duplicate(true)
		cb.detection.ship_sensor = {}
		cb.detection.equip_sensor = {}
		cb.detection.intellect_bands = []
		cb.detection.ship_points_div = 1
		cb.terrain = full.terrain)

func _edge(f: FleetState) -> float:
	var m := 0.0
	for p in f.form:
		m = maxf(m, p.rotated(f.heading).x)
	return m

func _state(foe_dx: float, comp: Array) -> String:
	var F := SalvoFixture
	var s := _sim([F.def("A", 400, 450, comp, true)], [F.def("B", 400.0 + foe_dx, 450, [["SHP-02", 4]], true)])
	s.st.fleets[0].heading = 0.0
	s.st.fleets[1].heading = 0.0
	s.step()
	s.step()
	return s.detect.state(0, s.st.fleets[1].id)

func _run() -> void:
	var D: Dictionary = SalvoFixture.combat().detection
	var view := float(D.view_r)
	var radar := float(D.radar_r)
	var s := _sim([SalvoFixture.def("A", 400, 450, [["SHP-04", 8]], true)], [SalvoFixture.def("B", 900, 450, [["SHP-02", 4]], true)])
	var a: FleetState = s.st.fleets[0]
	var b: FleetState = s.st.fleets[1]
	a.heading = 0.0
	b.heading = 0.0
	# 가장 가까운 두 함선 사이 거리 = 중심 거리 - A 앞끝 + B 뒤끝(B는 같은 방향 배치)
	var edge_a := _edge(a)
	var back_b := 0.0
	for p in b.form:
		back_b = minf(back_b, p.x)
	var base := edge_a - back_b   # 중심 거리 dx 일 때 최근접 간격 = dx - base (x축 정렬 가정)
	_check(_state(base + view - 5.0, [["SHP-04", 8]]) == "confirmed", "가시 범위 안(바깥 함선 + %d)" % view)
	_check(_state(base + view + 30.0, [["SHP-04", 8]]) != "confirmed", "가시 범위 밖은 점수 탐지 0이라 확인 아님")
	_check(_state(base + radar - 5.0, [["SHP-04", 7], ["SHP-06", 1]]) == "confirmed", "정찰함 레이더 안(%d)" % radar)
	_check(_state(base + radar + 30.0, [["SHP-04", 7], ["SHP-06", 1]]) != "confirmed", "레이더 밖")
	print("VIEW_RANGE_PASS" if _ok else "VIEW_RANGE_FAIL")
	quit(0 if _ok else 1)
