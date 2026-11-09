extends SceneTree
const Before = preload("res://tmp/i01b-followup-20261028/baseline/bundle_before.gd")
var _cases := 0
var _failures := 0
func _initialize() -> void:
	call_deferred("_run")
func _check(value: bool, label: String) -> void:
	_cases += 1
	if not value:
		_failures += 1
		push_error("EXACT_FAIL " + label)
func _run() -> void:
	var counts := range(41)
	counts.append_array([64, 100])
	for n in counts:
		for kind in range(-1, 11):
			for step in [0.0, 0.001, 1.0, 100.0, 173.25]:
				var a := Before.offsets(n, kind, step)
				var b := BundleLayout.offsets(n, kind, step)
				_check(a == b, "offsets n%d/k%d/s%s" % [n, kind, step])
	for n in [0, 1, 2, 3, 7, 29, 40]:
		for heading in [0.0, 0.73, PI]:
			for flip in [false, true]:
				for compact in [false, true]:
					var fleets := []
					for i in n:
						var fleet := FleetState.new()
						fleet.id = 100 - i
						# 동일 측방/전방 투영값도 포함하는 결정적 순서 fixture.
						fleet.pos = Vector2(20 + (i % 3) * 9, 20 + (i % 4) * 17)
						fleet.heading = heading
						fleet.flip = flip
						fleet.form.assign([Vector2(20 + i, 30)])
						fleet.form_t.assign([Vector2(200 + i, 70)])
						fleets.append(fleet)
					for kind in range(-1, 11):
						var world := Vector2(1600, 900) if not compact else Vector2(200, 150)
						var a := Before.slots(fleets, kind, 20.0, 10.0, world)
						var b := BundleLayout.slots(fleets, kind, 20.0, 10.0, world)
						_check(a == b and a.keys() == b.keys() and a.values() == b.values(), "slots n%d/k%d/h%s/f%s/c%s" % [n, kind, heading, flip, compact])
	print("BUNDLE_FROZEN_EXACT_PASS cases=%d failures=%d" % [_cases, _failures])
	quit(0 if _failures == 0 else 1)
