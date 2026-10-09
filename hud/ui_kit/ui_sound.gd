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
	"laser_light": {"bus": "Sfx", "file": "battle/laser_light", "synth": ["noise", 3000.0, 900.0, 0.2, 0.2], "gap": 0.15},
	"laser_heavy": {"bus": "Sfx", "file": "battle/laser_heavy", "synth": ["boom", 300.0, 90.0, 0.6, 0.5], "gap": 0.4},
	"missile_launch": {"bus": "Sfx", "file": "battle/missile_launch", "synth": ["noise", 1500.0, 400.0, 0.5, 0.3], "gap": 0.25},
	"missile_hit": {"bus": "Sfx", "file": "battle/missile_hit", "synth": ["boom", 200.0, 60.0, 0.5, 0.5], "gap": 0.1},
	"fighter_launch": {"bus": "Sfx", "file": "battle/fighter_launch", "synth": ["noise", 800.0, 2000.0, 0.6, 0.25], "gap": 0.4},
	"fighter_guns": {"bus": "Sfx", "file": "battle/fighter_guns", "synth": ["noise", 3500.0, 1500.0, 0.2, 0.2], "gap": 0.2},
	"fighter_dock": {"bus": "Sfx", "file": "battle/fighter_dock", "synth": ["tone", 500.0, 300.0, 0.25, 0.3], "gap": 0.3},
	"engine_boost": {"bus": "Sfx", "file": "battle/engine_boost", "synth": ["boom", 90.0, 160.0, 0.6, 0.4], "gap": 0.5},
	"shield_hit": {"bus": "Sfx", "file": "battle/shield_hit", "synth": ["tone", 1400.0, 700.0, 0.2, 0.3], "gap": 0.1},
	"armor_hit": {"bus": "Sfx", "file": "battle/armor_hit", "synth": ["boom", 400.0, 120.0, 0.15, 0.4], "gap": 0.1},
	"chain_explosion": {"bus": "Sfx", "file": "battle/chain_explosion", "synth": ["boom", 150.0, 40.0, 1.0, 0.7], "gap": 0.5},
	"fire_ignite": {"bus": "Sfx", "file": "battle/fire_ignite", "synth": ["noise", 1200.0, 300.0, 0.6, 0.3], "gap": 0.5},
	"fleet_lost": {"bus": "Ui", "file": "ui/fleet_lost", "synth": ["alarm", 440.0, 330.0, 0.7, 0.5], "gap": 1.0, "vibrate": 80},
}

# 루프 3종: 원샷 훅이 아니라 종류마다 재생기 하나(동시에 최대 3개). set_loop("engine_loop", 0.6)으로 켜고, 0이면 끈다.
const LOOPS := ["beam_loop", "engine_loop", "fire_loop"]

# 배경음악: 퍼블릭 도메인 고전을 반복 재생한다(출처는 assets/audio/music/README.md).
const MUSIC := ["stars_stripes"]
var _music: AudioStreamPlayer
var _music_i := 0
# 교전 중에는 〈산왕의 동굴에서〉를 반복한다. 교전 사건이 COMBAT_HOLD초 동안 없으면 평시 곡으로 돌아간다.
const COMBAT_TRACK := "mountain_king"
const COMBAT_HOLD := 10.0
const COMBAT_EVENTS := ["salvo", "volley", "laser_light", "laser_heavy", "missile_hit", "fighter_guns", "shield_hit", "armor_hit", "ship_kill"]
var _combat_until := 0.0
var _in_combat := false

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
var _loops := {}

# level 0~1. 0이면 멈춘다. 자산이 없으면 아무것도 하지 않는다(루프는 합성 임시음이 없다).
func set_loop(name: String, level: float) -> void:
	var lp: AudioStreamPlayer = _loops.get(name)
	if lp == null or lp.stream == null:
		return
	if level <= 0.001:
		lp.stop()
		return
	lp.volume_db = linear_to_db(clampf(level, 0.0, 1.0))
	if not lp.playing:
		lp.play()

func _ready() -> void:
	for b in ["Sfx", "Ui", "Music"]:
		if AudioServer.get_bus_index(b) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	for l in LOOPS:
		var lp := AudioStreamPlayer.new()
		lp.name = l
		lp.bus = "Sfx"
		var path: String = AUDIO_DIR + "battle/" + l + ".wav"
		if ResourceLoader.exists(path):
			lp.stream = load(path)
		add_child(lp)
		_loops[l] = lp
	apply_volume()
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.finished.connect(_next_music)
	add_child(_music)
	_next_music()

func _process(_dt: float) -> void:
	var c := Time.get_ticks_msec() / 1000.0 < _combat_until
	if c == _in_combat or _music == null:
		return
	_in_combat = c
	var path: String = AUDIO_DIR + "music/" + COMBAT_TRACK + ".ogg"
	if c and ResourceLoader.exists(path):
		var s: AudioStreamOggVorbis = load(path)
		s.loop = true
		_music.stream = s
		_music.play()
	elif not c:
		_next_music()

func _next_music() -> void:
	for n in MUSIC.size():
		var path: String = AUDIO_DIR + "music/" + MUSIC[_music_i % MUSIC.size()] + ".ogg"
		_music_i += 1
		if ResourceLoader.exists(path):
			_music.stream = load(path)
			_music.play()
			return

static func apply_volume() -> void:
	for it in [["Master", GameSettings.vol_master], ["Sfx", GameSettings.vol_sfx], ["Ui", GameSettings.vol_ui], ["Music", GameSettings.vol_music]]:
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
	if ev in COMBAT_EVENTS:
		_combat_until = now + COMBAT_HOLD
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
