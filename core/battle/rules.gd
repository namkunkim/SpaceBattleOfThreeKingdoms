class_name BattleRules
extends RefCounted

# POC 규칙의 순수 함수와 수치(M1: 규칙은 바꾸지 않는다). M2에서 수치는 data/로 옮긴다.
# 시간 단위는 틱(10Hz)이다. 초 단위 원값은 주석으로 남긴다.

const TICK_HZ := 10
const TICK_S := 0.1
# 기준 POC가 돌던 프레임 폭(20Hz). dt 보간식을 이 폭 기준 결과와 맞춘다.
const REF_DT := 0.05

const WORLD := Vector2(3400.0, 2300.0)
const SHIP_GAP := 20.0
const FORM_COUNT := 10
const FORM_NAMES := ["횡진", "쐐기진", "방진", "종진", "원진", "학익진", "사선진", "어린진", "안행진", "장사진"]
const CMD_R := 560.0
const MISSILE_R := 480.0
const FIGHTER_R := 380.0
const RANGE_R := 300.0
const MAX_VISIBLE := 28

const MILLI := 1000          # 척 수 1척 = 1000
const BP := 10000            # CP 1점 = 10000bp

const CP_MAX_BP := 10 * BP
const CP_START_BP := 3 * BP
const CP_REGEN_S := 4.5       # 플레이어 CP 1점 / 4.5초
const ECP_REGEN_S := 5.5      # 적 CP 1점 / 5.5초
const MISSILE_COST_BP := 2 * BP
const FIGHTER_COST_BP := 3 * BP
const CHARGE_COST_BP := 3 * BP

# 초 단위 값. 코어는 시작할 때 틱 수로 바꾼다(BattleRules.ticks). 10Hz 기준 틱 수를 옆에 적는다.
const MISSILE_CD_S := 18.0       # 180틱
const FIGHTER_CD_S := 26.0       # 260틱
const CHARGE_S := 10.0           # 100틱
const FLANK_MSG_S := 3.0         # 30틱
# 기준 POC는 ai_t를 실수 0.05씩 빼서 의도한 0.5초가 아니라 실제로 0.55초(11프레임)마다 돌았다.
# 기준선(m1_baseline.json)이 이 값으로 잡혔으므로 실효 값 0.55초를 유지한다(M3에서 0.5초로 정리할지 정한다).
# 10Hz에서 정수 틱으로 나눠지지 않아 AI 타이머만 밀리초로 센다(6틱·5틱이 번갈아 온다).
const AI_PERIOD_MS := 550
const REINF_MS := 95000          # 시계가 이 값을 넘는 첫 하위 걸음에 출현
# 함재기 수명은 밀리초로 센다. 기준 POC도 실수 0.05씩 빼서 의도한 9.0초가 아니라 181프레임(9.05초)을 살았다.
const SWARM_LIFE_MS := 9050
const SWARM_RETURN_MS := 1000    # 남은 수명 1초부터 귀환

const MISSILE_COUNT := 6
const MISSILE_HIT_R := 22.0
const SWARM_POINTS := 22
const SWARM_HIT_R := 120.0
const BASE_SPEED := 62.0
const TURN_RATE := 1.7           # rad/s

const ALLY_GAP := 110.0
const FOE_GAP := 90.0
const EDGE := 40.0

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

# 맞는 방향 피해 배율: 정면 <60° ×1.0, 측면 <120° ×1.3, 후면 ×1.6 (경계 처리는 M3에서 Q33으로)
static func flank_mul(att_pos: Vector2, tgt_pos: Vector2, tgt_heading: float) -> float:
	var a := atan2(att_pos.y - tgt_pos.y, att_pos.x - tgt_pos.x)
	var d := absf(ang_diff(tgt_heading, a))
	if d < PI / 3.0:
		return 1.0
	if d < PI * 2.0 / 3.0:
		return 1.3
	return 1.6

static func level_mul(lv: int) -> float:
	return 1.0 + 0.07 * (lv - 1)

# 화력 배율: 레벨, 돌격 ×1.35, 지휘 범위 밖 ×0.75, 방어진형 ×0.7
static func power(lv: int, charging: bool, in_cmd: bool, defense: bool) -> float:
	return level_mul(lv) * (1.35 if charging else 1.0) * (1.0 if in_cmd else 0.75) * (0.7 if defense else 1.0)

static func xp_need_milli(lv: int) -> int:
	return (20 + lv * 12) * MILLI

static func move_speed(spd: float, defense: bool, charging: bool) -> float:
	return BASE_SPEED * spd * (0.5 if defense else 1.0) * (1.4 if charging else 1.0)

# 표시 척 수(진형 슬롯 수). 함재기·미사일 발사 위치가 이 값으로 정해진다(M3에서 정리할 결함).
static func n_ships(ships_milli: int, max_milli: int) -> int:
	return maxi(1, mini(MAX_VISIBLE, ceili(28.0 * ships_milli / maxf(1.0, max_milli))))

static func quant(v: float) -> float:
	return floorf(v * 1000.0 + 0.5) / 1000.0

static func quant_v(p: Vector2) -> Vector2:
	return Vector2(quant(p.x), quant(p.y))

static func q_int(v: float) -> int:
	return int(floorf(v * 1000.0 + 0.5))

# 28척 진형 좌표 (x=전방, y=측면, 단위 px). 앞쪽 슬롯일수록 전열함이 배치된다.
static func formation_offsets(kind: int, dens: float) -> Array[Vector2]:
	var d := SHIP_GAP * dens
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
