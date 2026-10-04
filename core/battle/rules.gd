class_name BattleRules
extends RefCounted

# 단위 환산과 순수 수학, 진형 좌표. 규칙 수치(화력, 사거리, 비용, 시간 …)는 여기에 두지 않는다.
# 규칙 수치는 프로필 JSON(data/profiles/)에서 RuleSet이 읽는다.
# 시간 단위는 틱(10Hz)이다.

const TICK_HZ := 10
const TICK_S := 0.1
# 기준 POC가 돌던 프레임 폭(20Hz). 이 폭 기준 결과와 맞추려고 쓰는 단위 환산 상수다(규칙 값이 아니다).
const REF_DT := 0.05

const FORM_COUNT := 10
const FORM_NAMES := ["횡진", "쐐기진", "방진", "종진", "원진", "학익진", "사선진", "어린진", "안행진", "장사진"]

const MILLI := 1000          # 척 수 1척 = 1000
const BP := 10000            # CP 1점 = 10000bp

# 기준 프레임(20Hz)에서 한 번에 k만큼 다가가던 지수 보간을 dt 폭에 맞게 바꾼다: 1 − (1 − k)^(dt/0.05)
static func ticks(seconds: float, hz: int) -> int:
	return roundi(seconds * hz)

static func lerp_k(k_ref: float, dt: float) -> float:
	k_ref = minf(1.0, k_ref)
	return 1.0 - pow(1.0 - k_ref, dt / REF_DT)

static func ang_diff(a: float, b: float) -> float:
	var d := fmod(b - a, TAU)
	if d > PI:
		d -= TAU
	if d < -PI:
		d += TAU
	return d

static func quant(v: float) -> float:
	return floorf(v * 1000.0 + 0.5) / 1000.0

static func quant_v(p: Vector2) -> Vector2:
	return Vector2(quant(p.x), quant(p.y))

static func q_int(v: float) -> int:
	return int(floorf(v * 1000.0 + 0.5))

# 28척 진형 좌표 (x=전방, y=측면, 단위 px). gap은 슬롯 간격이다. 앞쪽 슬롯일수록 전열함이 배치된다.
# 슬롯 배치는 표시와 발사 위치용 기하이고 M3에서 본편 진형 7종으로 바뀐다(tests/data_rules.gd가 이 함수만 숫자 검사에서 뺀다).
static func formation_offsets(kind: int, gap: float) -> Array[Vector2]:
	var d := gap
	var pts: Array[Vector2] = []
	match kind:
		0: # 횡진: 2열 횡대
			for k in 28:
				pts.append(Vector2(-(k / 14) * d, (k % 14 - 6.5) * d))
		1: # 쐐기진: 전방 돌출 V
			pts.append(Vector2.ZERO)
			for k in range(1, 28):
				var rank := (k + 1) / 2
				pts.append(Vector2(-rank * d * 0.9, rank * d * (1.0 if k % 2 == 1 else -1.0)))
		2: # 방진: 4x7 방형
			for k in 28:
				pts.append(Vector2(-(k / 7) * d, (k % 7 - 3.0) * d))
		3: # 종진: 3열 종대
			for k in 28:
				pts.append(Vector2(-(k / 3) * d, (k % 3 - 1.0) * d))
		4: # 원진: 동심원
			pts.append(Vector2.ZERO)
			var rings := [[7, 1.4], [12, 2.6], [8, 3.6]]
			for rg in rings:
				for i in int(rg[0]):
					var a: float = TAU * i / int(rg[0])
					pts.append(Vector2(cos(a), sin(a)) * d * float(rg[1]))
		5: # 학익진: 양익이 앞으로 굽은 호
			for k in 28:
				var ly := (k - 13.5) * d * 0.85
				pts.append(Vector2(absf(ly) * 0.45, ly))
		6: # 사선진: 대각선 2열
			for k in 28:
				var line := k / 14
				var i := k % 14
				pts.append(Vector2((6.5 - i) * d * 0.7 - line * d, (i - 6.5) * d * 0.9 + line * d * 0.6))
		7: # 어린진: 엇갈린 6-5 배열
			var row := 0
			var placed := 0
			while placed < 28:
				var cols := 6 if row % 2 == 0 else 5
				for c in cols:
					if placed >= 28:
						break
					pts.append(Vector2(-row * d * 0.9, (c - (cols - 1) * 0.5) * d))
					placed += 1
				row += 1
		8: # 안행진: 후방 돌출 역V
			pts.append(Vector2.ZERO)
			for k in range(1, 28):
				var rank := (k + 1) / 2
				pts.append(Vector2(rank * d * 0.9, rank * d * (1.0 if k % 2 == 1 else -1.0)))
		_: # 장사진: 2열 장사 종대(엇갈림)
			for k in 28:
				pts.append(Vector2(-(k / 2) * d * 0.8, ((k % 2) - 0.5) * d * 1.1 + sin(k * 0.45) * d * 0.5))
	var c := Vector2.ZERO
	for p in pts:
		c += p
	c /= pts.size()
	for i in pts.size():
		pts[i] -= c
	return pts

static func ship_pos(pos: Vector2, heading: float, form: Array[Vector2], i: int) -> Vector2:
	return pos + form[i % form.size()].rotated(heading)
