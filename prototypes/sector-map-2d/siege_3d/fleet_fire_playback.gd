extends Node
## Samples the reference encounter and plays its weapon sounds without a camera or fleet scene.

const Combat := preload("res://tactical_fleet_combat.gd")
const MISSILE_LAUNCH := preload("res://siege_3d/missile_launch.wav")
const CANNON_FIRE := preload("res://siege_3d/volley.wav")
const MISSILE_HIT := preload("res://siege_3d/missile_hit.wav")
const ARMOR_HIT := preload("res://siege_3d/armor_hit.wav")
const LENGTH := 107.0
const RAILGUN_CYCLE := 2.4
const RAILGUN_FLIGHT := 0.40
const RAILGUN_IMPACT := 0.12

var shu_count := 0
var wei_count := 0
var elapsed := 0.0
var active_shots: Array[Dictionary] = []
var manual_salvo := {}
var voices: Array[AudioStreamPlayer] = []
var heard_phases := {}


func _ready() -> void:
	for i in 4:
		var player := AudioStreamPlayer.new()
		add_child(player)
		voices.append(player)
	_sample_fire()


func restart() -> void:
	stop_audio()
	manual_salvo.clear()
	elapsed = 0.0
	_sample_fire()


func stop_audio() -> void:
	for player in voices:
		player.stop()
	heard_phases.clear()

func set_audio_paused(paused: bool) -> void:
	for player in voices:
		player.stream_paused = paused

func advance(delta: float, play_audio := true) -> void:
	if elapsed >= LENGTH:
		stop_audio()
		if not manual_salvo.is_empty():
			manual_salvo.start = 0.0
		elapsed = 0.0
	elapsed = minf(elapsed + delta, LENGTH)
	_sample_fire()
	if play_audio:
		_sync_fire_audio()

func _sync_fire_audio() -> void:
	var phases := {}
	for shot in active_shots:
		var emitter: int = shot.emitter
		if emitter not in [0, 5, 101, 102, 103, 200, 213, 260]:
			continue
		var impact: bool = shot.impact
		phases[emitter] = impact
		if heard_phases.get(emitter) == impact:
			continue
		for player in voices:
			if player.playing:
				continue
			if shot.weapon == Combat.Weapon.MISSILE:
				player.stream = MISSILE_HIT if impact else MISSILE_LAUNCH
			else:
				player.stream = ARMOR_HIT if impact else CANNON_FIRE
			player.volume_db = -16
			player.play()
			break
	heard_phases = phases

func fire_salvo(source: int, target: int) -> void:
	manual_salvo = {"source": source, "target": target, "start": elapsed}
	_sample_fire()


func _sample_manual_salvo() -> void:
	if manual_salvo.is_empty():
		return
	var age: float = elapsed - manual_salvo.start
	if age < 0.0 or age >= 1.8:
		manual_salvo.clear()
		return
	_append_shot(manual_salvo.source, manual_salvo.target, 101, Combat.Weapon.RAILGUN, age, 0.42, 0.10)
	_append_shot(manual_salvo.source, manual_salvo.target, 103, Combat.Weapon.LASER, age - 0.23, 0.16, 0.09)
	_append_shot(manual_salvo.source, manual_salvo.target, 102, Combat.Weapon.MISSILE, age - 0.46, 1.1, 0.15)


func _sample_fire() -> void:
	active_shots.clear()
	if shu_count > 0 and wei_count > 0 and elapsed < 102.1:
		_sample_railguns()
		_sample_missiles_and_lasers()
		_sample_concentrated_volleys()
	_sample_manual_salvo()


func _sample_railguns() -> void:
	for side in 2:
		var count := shu_count if side == 0 else wei_count
		for slot in count:
			# Spread each side's shots across its reload cycle so even small ships join in.
			var clock := elapsed + (float(slot) + 0.5 * side) * RAILGUN_CYCLE / count
			var age := fposmod(clock, RAILGUN_CYCLE)
			if age >= RAILGUN_FLIGHT + RAILGUN_IMPACT:
				continue
			var turn := floori(clock / RAILGUN_CYCLE)
			var source := _live_ship(side, slot)
			var target := _live_ship(1 - side, slot * 7 + turn * 5)
			_append_shot(source, target, 200 + source, Combat.Weapon.RAILGUN,
				age, RAILGUN_FLIGHT, RAILGUN_IMPACT, 0.16)


func _sample_missiles_and_lasers() -> void:
	for i in 8:
		var clock := elapsed + i * 0.47
		var cycle := 3.5 + fmod(i * 0.39, 1.25)
		var turn := floori(clock / cycle)
		var side := i % 2
		_append_shot(_live_ship(side, i * 7 + turn * 3), _live_ship(1 - side, i * 11 + turn * 5),
			i, Combat.Weapon.MISSILE, fposmod(clock, cycle), 1.48 + (i % 3) * 0.16, 0.18)
	for side in 2:
		var cycle := 4.4 + side * 0.4
		var clock := elapsed + side * 2.1
		var turn := floori(clock / cycle)
		_append_shot(_live_ship(side, side * 4 + turn * 7), _live_ship(1 - side, turn * 9 + side),
			30 + side, Combat.Weapon.LASER, fposmod(clock, cycle), 0.20, 0.10)


func _sample_concentrated_volleys() -> void:
	for window in [[50.8, 1.2, 5], [63.0, 1.0, 8], [74.65, 1.05, 11], [85.25, 1.0, 2]]:
		var start: float = window[0]
		var flight: float = window[1]
		if elapsed < start or elapsed >= start + flight + 2.6:
			continue
		for j in 9:
			var target := _live_ship(1, int(window[2]) + (j % 3) * 3)
			_append_shot(_live_ship(0, j * 7 + 3), target, 400 + j, Combat.Weapon.MISSILE,
				elapsed - start - j * 0.14, flight, flight * 0.8, 1.0, true)


func _append_shot(source: int, target: int, emitter: int, weapon: Combat.Weapon, age: float,
		flight: float, impact_time: float, damage_scale := 1.0, salvo := false) -> void:
	if age < 0.0 or age >= flight + impact_time:
		return
	var impact := age >= flight
	var progress := (age - flight) / impact_time if impact else age / flight
	active_shots.append({
		"source": source, "target": target, "weapon": weapon, "emitter": emitter,
		"phase": 0.72 + progress * 0.1 if impact else progress * 0.72,
		"progress": progress, "impact": impact, "damage_scale": damage_scale, "salvo": salvo,
	})


func _live_ship(side: int, choice: int) -> int:
	var side_count := shu_count if side == 0 else wei_count
	return (0 if side == 0 else shu_count) + posmod(choice, side_count)
