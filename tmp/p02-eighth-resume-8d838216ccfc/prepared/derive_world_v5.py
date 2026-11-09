"""Derive V5 WorldMap probe without changing the preserved V4."""
from pathlib import Path

here = Path(__file__).resolve().parent
source = (here / "world-product-v4.gd").read_text(encoding="utf-8-sig")
original = """		var result := w.outcome
		await process_frame
		await process_frame
		var fingerprint: String = resolver.sim.fingerprint()
"""
guarded = """		if Time.get_ticks_msec() >= deadline:
			fail_complete(resolver, visible_count[0], "deadline-175000ms")
			return
		if resolver._thread != null or w.state != "result" or w.outcome == null:
			fail_complete(resolver, visible_count[0], "unexpected-terminal-state")
			return
		var result := w.outcome
		await process_frame
		await process_frame
		if resolver._thread != null or resolver.sim == null:
			fail_complete(resolver, visible_count[0], "terminal-worker-or-sim-invalid")
			return
		var fingerprint: String = resolver.sim.fingerprint()
"""
assert source.count(original) == 1
source = source.replace(original, guarded)
helper = """func fail_complete(resolver: AutoResolver, shown: int, reason: String) -> void:
	# Persist failure before the synchronous join. An unresponsive worker is
	# handled by the external owned Job deadline. Never read sim here.
	check("complete-aborted", false, {"reason":reason,"state":w.state,
		"worker_present":resolver._thread != null,"result_visible":w._result.visible,"show_count":shown})
	if w.resolver == resolver:
		w._cancel_resolve()
	else:
		resolver.cancel()
	var joined := resolver._thread == null
	var no_result := w.outcome == null and resolver.outcome == null and not w._result.visible and shown == 0
	check("abort-joined-without-result", joined and resolver._cancel and no_result and w.resolver == null and w.state == "browse" and not w._resolve.visible,
		{"thread_joined":joined,"cancelled":resolver._cancel,"screen_outcome_absent":w.outcome == null,
		"resolver_outcome_absent":resolver.outcome == null,"result_visible":w._result.visible,
		"resolve_visible":w._resolve.visible,"show_count":shown,"state":w.state,"resolver_released":w.resolver == null})
	quit(1)

"""
assert source.count("func _run() -> void:") == 1
source = source.replace("func _run() -> void:", helper + "func _run() -> void:")
with (here / "world-product-v5.gd").open("x", encoding="utf-8") as f:
    f.write(source)
