class_name UiSound
extends Node

# 효과음 훅과 음량. 사건 이름으로 부른다: sound.play("alert")
# - 자산: res://assets/audio/<file>.ogg|.wav가 있으면 그것을 쓴다. 자산은 라이선스 확인·사용자 승인 뒤에 들인다.
# - 자산이 없으면 코드로 합성한 임시음(짧은 음·잡음)을 쓴다. 외부 자산이 아니므로 라이선스 문제가 없다.
# - 버스: Master ← 전투(Sfx), UI(Ui). 음량은 GameSettings(0~1), 0이면 끈다.
# - 접근성(EXPERIENCE-DESIGN §7): 경보·결정·아군 손실은 화면 표시(알림 띠·교신)와 진동을 함께 낸다.

const AUDIO_DIR := "res://assets/audio/"
const RATE := 22050

# 사건: bus, file(자산 이름), synth [종류, 시작 Hz, 끝 Hz, 길이 초, 크기], gap(최소 간격 초), vibrate(ms)
const EVENTS := {
	"button": {"bus": "Ui", "file": "ui/button", "synth": ["tone", 1250.0, 1150.0, 0.035, 0.35], "gap": 0.04},
	"tab": {"bus": "Ui", "file": "ui/tab", "synth": ["tone", 900.0, 1000.0, 0.04, 0.3], "gap": 0.04},
	"confirm": {"bus": "Ui", "file": "ui/confirm", "synth": ["tone", 660.0, 990.0, 0.09, 0.4], "gap": 0.08},
	"confirm_heavy": {"bus": "Ui", "file": "ui/confirm_heavy", "synth": ["tone", 330.0, 660.0, 0.22, 0.55], "gap": 0.1, "vibrate": 40},
	"denied": {"bus": "Ui", "file": "ui/denied", "synth": ["square", 220.0, 180.0, 0.12, 0.3], "gap": 0.2},
	"undo": {"bus": "Ui", "file": "ui/undo", "synth": ["tone", 990.0, 660.0, 0.1, 0.4], "gap": 0.1},
	"pause": {"bus": "Ui", "file": "ui/pause", "synth": ["tone", 520.0, 390.0, 0.12, 0.4], "gap": 0.1},
	"alert": {"bus": "Ui", "file": "ui/alert", "synth": ["alarm", 880.0, 660.0, 0.5, 0.5], "gap": 1.0, "vibrate": 60},
	"decision": {"bus": "Ui", "file": "ui/decision", "synth": ["tone", 523.0, 784.0, 0.35, 0.5], "gap": 0.5, "vibrate": 40},
	"salvo": {"bus": "Sfx", "file": "battle/salvo", "synth": ["boom", 260.0, 70.0, 0.7, 0.6], "gap": 0.3},
	"warn_branch": {"bus": "Ui", "file": "ui/warn_branch", "synth": ["tone", 740.0, 880.0, 0.18, 0.45], "gap": 1.0, "vibrate": 30},
	"volley": {"bus": "Sfx", "file": "battle/volley", "synth": ["noise", 2400.0, 600.0, 0.16, 0.22], "gap": 0.09},
	"ship_kill": {"bus": "Sfx", "file": "battle/ship_kill", "synth": ["boom", 180.0, 50.0, 0.45, 0.45], "gap": 0.07},
	"fleet_destroyed": {"bus": "Sfx", "file": "battle/fleet_destroyed", "synth": ["boom", 120.0, 30.0, 1.3, 0.8], "gap": 0.5},
	"fleet_lost": {"bus": "Ui", "file": "ui/fleet_lost", "synth": ["alarm", 440.0, 330.0, 0.7, 0.5], "gap": 1.0, "vibrate": 80},
}

static var history: Array = []   # 최근 사건(테스트·디버그용)
# 음높이 흔들기 전용 난수(리뷰 W-4). 전역 난수를 쓰면 POC 규칙 난수열이 밀려 결정론이 깨진다.
var _rng := RandomNumberGenerator.new()

# 진동은 모두 여기로(설정 "진동"으로 끈다, 리뷰 W-7)
static func vibrate(ms: int) -> void:
	if GameSettings.vibrate:
		Input.vibrate_handheld(ms)

var _streams := {}
var _last := {}
var _players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	for b in ["Sfx", "Ui"]:
		if AudioServer.get_bus_index(b) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	apply_volume()

static func apply_volume() -> void:
	for it in [["Master", GameSettings.vol_master], ["Sfx", GameSettings.vol_sfx], ["Ui", GameSettings.vol_ui]]:
		var i := AudioServer.get_bus_index(it[0])
		if i < 0:
			continue
		var v: float = it[1]
		AudioServer.set_bus_mute(i, v <= 0.001)
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))

func play(ev: String) -> void:
	var spec: Dictionary = EVENTS.get(ev, {})
	if spec.is_empty():
		push_warning("UiSound: 알 수 없는 사건 " + ev)
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(ev, -99.0)) < float(spec.get("gap", 0.05)):
		return
	_last[ev] = now
	history.append(ev)
	if history.size() > 64:
		history.pop_front()
	if spec.has("vibrate"):
		vibrate(int(spec.vibrate))
	var p := _free_player()
	if p == null:
		return
	p.stream = _stream(ev, spec)
	p.bus = spec.bus
	p.pitch_scale = _rng.randf_range(0.96, 1.04) if spec.bus == "Sfx" else 1.0
	p.play()

func _free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return null

func _stream(ev: String, spec: Dictionary) -> AudioStream:
	if _streams.has(ev):
		return _streams[ev]
	var s: AudioStream = null
	for ext in [".ogg", ".wav"]:
		var path: String = AUDIO_DIR + spec.file + ext
		if ResourceLoader.exists(path):
			s = load(path)
			break
	if s == null:
		s = _synth(spec.synth)
	_streams[ev] = s
	return s

# 임시음 합성: tone(사인 미끄럼), square, alarm(두 음 반복), noise(높은 잡음 쓸림), boom(낮은 잡음 + 저음)
static func _synth(p: Array) -> AudioStreamWAV:
	var kind: String = p[0]
	var f0: float = p[1]
	var f1: float = p[2]
	var dur: float = p[3]
	var amp: float = p[4]
	var n := int(RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var ph := 0.0
	var lp := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind) ^ int(f0)
	for i in n:
		var t := float(i) / n
		var f := lerpf(f0, f1, t)
		var env := minf(1.0, t * 40.0) * pow(1.0 - t, 1.6 if kind != "boom" else 2.4)
		var v := 0.0
		match kind:
			"tone":
				ph += TAU * f / RATE
				v = sin(ph)
			"square":
				ph += TAU * f / RATE
				v = signf(sin(ph)) * 0.6
			"alarm":
				var ff := f0 if int(t * 6.0) % 2 == 0 else f1
				ph += TAU * ff / RATE
				v = sin(ph) * 0.8 + sin(ph * 2.0) * 0.2
			"noise":
				var k := clampf(f / RATE * 2.0, 0.02, 1.0)
				lp += (rng.randf_range(-1.0, 1.0) - lp) * k
				v = lp * 1.6
			"boom":
				ph += TAU * f / RATE
				lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.08
				v = sin(ph) * 0.7 + lp * 2.2
		var s := clampi(int(v * env * amp * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, s)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
