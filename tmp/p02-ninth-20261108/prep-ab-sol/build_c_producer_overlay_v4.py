"""Generate unexecuted review copies for the actual C producer. No project writes."""
from difflib import unified_diff
from hashlib import sha256
import json
from pathlib import Path

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
OUT=HERE/"c-producer-overlay-review-v4"
DETECT="core/battle/detection.gd"
SUITE="tests/i01b_service_state.gd"

HELPER='''
# Review overlay only. K6 scope is created by _detection and cleared before suffix.
var _k6_scopes: Dictionary = {}
var _k6_next_id := 0
var _k6_ordinal := 0

func _k6_record(sim: BattleSim, kind: String, phase: String, payload: Dictionary) -> void:
	var scope: Dictionary = _k6_scopes[sim.get_instance_id()]
	print("K6_C_PRODUCER ", JSON.stringify({
		"stream_ordinal": _k6_ordinal, "mono_usec": Time.get_ticks_usec(),
		"sim_id": scope.id, "actor": scope.actor, "case": scope.case,
		"seed": sim.st.seed_id, "tick": sim.st.tick, "event": kind, "phase": phase,
		"payload_hex": var_to_bytes(payload).hex_encode(),
	}))
	_k6_ordinal += 1

func _k6_register(sim: BattleSim, actor: String, wanted: String) -> void:
	_k6_next_id += 1
	_k6_scopes[sim.get_instance_id()] = {"id": _k6_next_id, "actor": actor, "case": wanted, "phase": "before-relocate"}
	_k6_record(sim, "initial", "fixture", {"contacts": sim.detect.contacts})
	sim.detect.set_meta("k6_review_observer", _k6_before_eval.bind(sim))

func _k6_before_eval(side: int, sim: BattleSim) -> void:
	# Observations contain raw sensing inputs and never copy Detection.score/contacts as oracle.
	var fleets: Array = []
	for f in sim.st.fleets:
		fleets.append({"id": f.id, "side": f.side, "position": f.pos, "form_offsets": f.form,
			"dead": f.dead, "max_hull": f.max_hull, "equipment": f.equip, "stats": f.stats,
			"formation": f.formation_id, "composition": f.comp0, "stages": f.stages})
	var scope: Dictionary = _k6_scopes[sim.get_instance_id()]
	_k6_record(sim, "eval", scope.phase, {"authoritative_tick": sim.st.tick, "evaluating_side": side,
		"fleets": fleets, "detection_config": sim.detect.D, "terrain_zones": sim.detect.terr.zones,
		"formation_config": sim.salvo.C.formations, "has_chain": sim.chain != null, "has_skills": sim.skills != null})

func _k6_raw_sha256(bytes: PackedByteArray) -> String:
	var hash := HashingContext.new()
	if hash.start(HashingContext.HASH_SHA256) != OK or hash.update(bytes) != OK:
		return ""
	return hash.finish().hex_encode()

func _k6_restore_call(a: BattleSim, b: BattleSim, packet: Dictionary, phase: String) -> Dictionary:
	if not _k6_scopes.has(b.get_instance_id()):
		return Service.restore_into_prepared_target(b, packet)
	# Capture actual call and returned value, with no retry or substituted result.
	var target_scope: Dictionary = _k6_scopes[b.get_instance_id()]
	var request_id := "%d/%s" % [target_scope.id, phase]
	_k6_record(a, "source-before", phase, {"request_id": request_id, "state": _all(a), "live_raw": var_to_bytes(_k6_live(a)).hex_encode()})
	var packet_raw := var_to_bytes(packet)
	_k6_record(b, "restore-request", phase, {"request_id": request_id, "state": _all(b), "packet": packet,
		"packet_raw": packet_raw.hex_encode(), "packet_raw_sha256": _k6_raw_sha256(packet_raw), "live_raw": var_to_bytes(_k6_live(b)).hex_encode()})
	var actual := Service.restore_into_prepared_target(b, packet)
	var after_raw := var_to_bytes(packet)
	_k6_record(b, "restore-result", phase, {"request_id": request_id, "state": _all(b), "packet": packet,
		"packet_raw": after_raw.hex_encode(), "packet_raw_sha256": _k6_raw_sha256(after_raw),
		"result": actual, "live_raw": var_to_bytes(_k6_live(b)).hex_encode()})
	_k6_record(a, "source-after", phase, {"request_id": request_id, "state": _all(a), "live_raw": var_to_bytes(_k6_live(a)).hex_encode()})
	return actual

func _k6_live(sim: BattleSim) -> Dictionary:
	var roster: Array = []
	var positions: Dictionary = {}
	for fleet in sim.st.fleets:
		roster.append({"id": fleet.id, "side": fleet.side, "faction": fleet.faction})
		positions[fleet.id] = fleet.pos
	return {"profile_id": sim.profile_id, "seed": sim.st.seed_id, "hz": sim.st.hz, "tick": sim.st.tick,
		"clock_ms": sim.st.clock_ms, "roster": roster, "contacts": sim.detect.contacts,
		"fleet_positions": positions, "receipt_metadata": {"ordinal": _k6_ordinal, "mono_ns": Time.get_ticks_usec() * 1000}}

func _k6_end_scope(sim: BattleSim) -> void:
	_k6_record(sim, "scope-end", "before-suffix", {})
	sim.detect.remove_meta("k6_review_observer")
	_k6_scopes.erase(sim.get_instance_id())
'''

def replace(text,old,new):
    if text.count(old)!=1:
        raise ValueError(f"source anchor not unique: {old!r}")
    return text.replace(old,new,1)

def detector(text):
    return replace(text,"func _eval(side: int) -> void:\n\tvar st := sim.st",
        'func _eval(side: int) -> void:\n\tif side == 1:\n\t\tvar observer: Variant = get_meta("k6_review_observer", Callable())\n\t\tif observer is Callable and observer.is_valid():\n\t\t\tobserver.call(side)\n\tvar st := sim.st')

def suite(text):
    text=replace(text,"\tvar b := _fixture(seed_id, true, false)\n\t_advance(a, 2 * a.st.hz)",
        "\tvar b := _fixture(seed_id, true, false)\n\t_k6_register(a, \"native-source\", wanted)\n\t_k6_register(b, \"restore-target\", wanted)\n\t_advance(a, 2 * a.st.hz)")
    text=replace(text,"\tfor sim in [a, b]: sim.st.fleets[1].pos = Vector2(1500, 450)",
        "\tfor sim in [a, b]:\n\t\tsim.st.fleets[1].pos = Vector2(1500, 450)\n\t\t_k6_scopes[sim.get_instance_id()].phase = \"after-relocate\"\n\t\t_k6_record(sim, \"relocate\", \"fixture\", {\"id\": sim.st.fleets[1].id, \"pos\": sim.st.fleets[1].pos})")
    text=replace(text,"\tvar answer := Service.restore_into_prepared_target(b, packet)",
        "\tvar answer := _k6_restore_call(a, b, packet, label + \"/primary\")")
    text=replace(text,"_check(Service.restore_into_prepared_target(b, packet).ok and _same(again, _all(b)), label + \" repeated apply adds no effects\")",
        "_check(_k6_restore_call(a, b, packet, label + \"/repeat\").ok and _same(again, _all(b)), label + \" repeated apply adds no effects\")")
    text=replace(text,"_check(Service.restore_into_prepared_target(b, wrong).ok and a.fingerprint() != b.fingerprint(), \"re-observing actual position diverges\")",
        "_check(_k6_restore_call(a, b, wrong, \"wrong-position-control\").ok and a.fingerprint() != b.fingerprint(), \"re-observing actual position diverges\")")
    text=replace(text,"\tpacket.detection.contacts[0][id].pos = Vector2.ZERO",
        "\t_k6_record(a, \"alias-before\", wanted, {\"state\": _all(a)})\n\t_k6_record(b, \"alias-before\", wanted, {\"state\": _all(b)})\n\tpacket.detection.contacts[0][id].pos = Vector2.ZERO\n\t_k6_record(a, \"alias-after\", wanted, {\"state\": _all(a), \"packet\": packet})\n\t_k6_record(b, \"alias-after\", wanted, {\"state\": _all(b)})")
    text=replace(text,"\t_restore(a, b, _capture(a), wanted + \" repaired\")\n\tvar suffix",
        "\t_restore(a, b, _capture(a), wanted + \" repaired\")\n\t_k6_end_scope(a)\n\t_k6_end_scope(b)\n\tvar suffix")
    return text+HELPER

if __name__=="__main__":
    OUT.mkdir(exist_ok=False)
    result={}
    for rel,transform in ((DETECT,detector),(SUITE,suite)):
        raw=(ROOT/rel).read_bytes()
        text=raw.decode("utf8").replace("\r\n","\n")
        changed=transform(text)
        dest=OUT/Path(rel).name
        dest.write_bytes(changed.encode("utf8"))
        delta=dest.with_suffix(".diff")
        delta.write_bytes("".join(unified_diff(text.splitlines(keepends=True),changed.splitlines(keepends=True),f"source/{rel}",f"overlay/{rel}")).encode("utf8"))
        result[rel]=dict(source_sha256=sha256(raw).hexdigest(),overlay_sha256=sha256(dest.read_bytes()).hexdigest(),
                         normalized_diff_sha256=sha256(delta.read_bytes()).hexdigest())
    (OUT/"SHA.json").write_bytes((json.dumps(result,indent=2)+"\n").encode("utf8"))
