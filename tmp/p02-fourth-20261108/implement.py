from pathlib import Path

root = Path.cwd()
evidence = root / "tmp/p02-fourth-20261108"
owner = root / "core/battle/operation_private_state.gd"
original = (evidence / "owner.before.gd.txt").read_bytes()
assert owner.read_bytes() == original
runner = root / "tests/p02_viewer_events.gd"
assert not runner.exists()
newline = b"\r\n" if b"\r\n" in original else b"\n"
method = """# Serial display drain. This consumes the same queue as the raw drain.
func drain_events_for(side: Variant) -> Dictionary:
	var error := _guard()
	if error != "": return {"ok": false, "error": error, "path": "owner"}
	if typeof(side) != TYPE_INT or side not in [0, 1]: return {"ok": false, "error": "invalid_side", "path": "side"}
	_busy = true
	var events := _sim.drain_events_for(side).duplicate(true)
	_busy = false
	return {"ok": true, "events": events}

"""
hunk = method.replace("\n", newline.decode()).encode()
anchor = b"# Read-only consumer DTOs."
assert original.count(anchor) == 1
(evidence / "owned-hunk.gd.txt").write_bytes(hunk)
runner.write_bytes((evidence / "runner.pre.gd.txt").read_bytes().replace(b"data.max_ticks = 120", b"data.max_ticks = NEAR_STEPS"))
owner.write_bytes(original.replace(anchor, hunk + anchor))
assert owner.read_bytes().replace(hunk, b"", 1) == original
