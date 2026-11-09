from pathlib import Path
import hashlib

root = Path(__file__).resolve().parent
base = root / "c-producer-overlay-review-v4" / "i01b_service_state.gd"
src = base.read_bytes()
assert hashlib.sha256(src).hexdigest() == "1eac3efd00a9b274b3d9f56b10f7dcf786a7ac6a428e9482c5e475db89209ed9"
source = src.decode("utf-8").replace("\r\n", "\n")

def replace(before, after):
    global source
    if source.count(before) != 1:
        raise ValueError(before)
    source = source.replace(before, after)

replace('''		a.step()
		b.step()
		_check(a.fingerprint() == b.fingerprint(), label + " fingerprint suffix")
		_check(_same(_all(a), _all(b)), label + " exact state and events suffix")
		_check(_same(a.drain_events(), b.drain_events()), label + " event order suffix")''', '''		var a_before := _k6_suffix_inputs(a)
		var b_before := _k6_suffix_inputs(b)
		a.step()
		b.step()
		var a_fp := a.fingerprint()
		var b_fp := b.fingerprint()
		_check(a_fp == b_fp, label + " fingerprint suffix")
		var a_all := _all(a)
		var b_all := _all(b)
		_check(_same(a_all, b_all), label + " exact state and events suffix")
		var a_events := a.drain_events()
		var b_events := b.drain_events()
		_check(_same(a_events, b_events), label + " event order suffix")
		_k6_extra("suffix", {"index": i, "source_tick": a.st.tick, "target_tick": b.st.tick,
			"source_before": a_before, "target_before": b_before,
			"source_after": _k6_suffix_inputs(a), "target_after": _k6_suffix_inputs(b),
			"source_all": a_all, "target_all": b_all, "source_events": a_events, "target_events": b_events,
			"source_fingerprint": a_fp, "target_fingerprint": b_fp})''')
replace('\tif b.supply: _check(is_same(b.supply.sim', '''	if b.detect and not _k6_extension.is_empty():
		_k6_extra("identity", {"request_id": _k6_last_primary, "tick": a.st.tick, "pairs": _k6_identity(a, b, packet)})
	if b.supply: _check(is_same(b.supply.sim''')
replace('\t_restore(a, b, packet, wanted)\n', '''	_k6_extension = {"seed": seed_id, "case": wanted, "source_id": _k6_scopes[a.get_instance_id()].id,
		"target_id": _k6_scopes[b.get_instance_id()].id}
	_restore(a, b, packet, wanted)
	var primary := _k6_last_primary
''')
replace('\tpacket.detection.contacts[0][id].pos = Vector2.ZERO\n', '''	var before_packet := var_to_bytes(packet)
	var before_source := _all(a)
	var before_target := _all(b)
	packet.detection.contacts[0][id].pos = Vector2.ZERO
	_k6_extra("mutation", {"request_id": primary, "tick": a.st.tick, "id": id,
		"packet_before": before_packet, "packet_after": var_to_bytes(packet),
		"source_before": before_source, "source_after": _all(a),
		"target_before": before_target, "target_after": _all(b)})
''')
replace('\t_suffix(a, b, suffix, wanted)\n', '\t_suffix(a, b, suffix, wanted)\n\t_k6_extension.clear()\n')
replace('\tvar packet_raw := var_to_bytes(packet)\n', '''	if phase.ends_with("/primary"):
		_k6_last_primary = request_id
	var packet_raw := var_to_bytes(packet)
''')
source += '''

# Supplemental stream preserves the original raw stream and its frozen ordinals.
var _k6_extension: Dictionary = {}
var _k6_last_primary: String
var _k6_extra_ordinal := 0

func _k6_extra(kind: String, payload: Dictionary) -> void:
	if _k6_extension.is_empty():
		return
	print("K6_C_EXTENSION ", JSON.stringify({
		"version": 1, "ordinal": _k6_extra_ordinal, "base_ordinal_next": _k6_ordinal,
		"case": _k6_extension, "event": kind, "payload_hex": var_to_bytes(payload).hex_encode(),
	}))
	_k6_extra_ordinal += 1

func _k6_suffix_inputs(sim: BattleSim) -> Dictionary:
	if _k6_extension.is_empty():
		return {}
	return {"command_log": sim.command_log.duplicate(true), "queue": sim._queue.duplicate(true)}

func _k6_identity(a: BattleSim, b: BattleSim, packet: Dictionary) -> Array:
	var pairs: Array = []
	for peer in ["source", "packet"]:
		var contacts: Array = a.detect.contacts if peer == "source" else packet.detection.contacts
		pairs.append([peer, -1, null, is_same(b.detect.contacts, contacts)])
		for side in 2:
			pairs.append([peer, side, null, is_same(b.detect.contacts[side], contacts[side])])
			for id in b.detect.contacts[side]:
				pairs.append([peer, side, id, not contacts[side].has(id) or is_same(b.detect.contacts[side][id], contacts[side][id])])
	return pairs
'''
with (root / "c-actual-extension-review-v1.gd").open("x", encoding="utf-8", newline="\n") as output:
    output.write(source)

