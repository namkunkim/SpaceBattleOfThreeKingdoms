"""Derive review-only Q/C suite overlays from exact source needles."""
from difflib import unified_diff
from hashlib import sha256
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent / "capture-overlays-review"

Q_PATH = "tests/p02_headless_adapter.gd"
C_PATH = "tests/i01b_service_state.gd"

Q_HELPER = '''
func _k6_q_stream(stream: String, kind: String, policy: String, seed_id: int, tick: int, commands: Array) -> void:
	var rows: Array = []
	for command in commands:
		rows.append({"ordinal": rows.size(), "typed_tuple": var_to_bytes(command).hex_encode()})
	print("K6_CAPTURE ", stream, " ", JSON.stringify({"case": kind + "/" + policy, "seed": seed_id, "tick": tick, "commands": rows}))
'''

C_HELPER = '''
func _k6_c_stream(stream: String, sim: BattleSim, label: String) -> void:
	if sim.detect == null:
		return
	for side in 2:
		var rows: Array = []
		for id in sim.detect.contacts[side]:
			rows.append({"id": id, "typed_payload": var_to_bytes(sim.detect.contacts[side][id]).hex_encode()})
		print("K6_CAPTURE ", stream, " ", JSON.stringify({"case": "detection", "seed": sim.st.seed_id, "phase": label, "side": side, "records": rows}))
'''

def replace(source, old, new):
    if source.count(old) != 1:
        raise ValueError(f"expected exactly one source location: {old!r}")
    return source.replace(old, new, 1)

def q_overlay(source):
    old = ('\t\tfor command in Cli._operation_policy_commands(policy, owner.read_projection(0).projection):\n'
           '\t\t\tcheck(owner.queue(command).ok, "policy queue")\n'
           '\t\tfor command in reference_commands(policy, public_raw): raw.queue(command)')
    new = ('\t\tvar k6_product_commands := Cli._operation_policy_commands(policy, owner.read_projection(0).projection)\n'
           '\t\t_k6_q_stream("q-product", kind, policy, seed_id, raw.st.tick, k6_product_commands)\n'
           '\t\tfor command in k6_product_commands:\n'
           '\t\t\tcheck(owner.queue(command).ok, "policy queue")\n'
           '\t\tvar k6_native_commands := reference_commands(policy, public_raw)\n'
           '\t\t_k6_q_stream("q-native", kind, policy, seed_id, raw.st.tick, k6_native_commands)\n'
           '\t\tfor command in k6_native_commands: raw.queue(command)')
    return replace(source, old, new) + Q_HELPER

def c_overlay(source):
    old = '\tvar answer := Service.restore_into_prepared_target(b, packet)'
    new = ('\t_k6_c_stream("c-source-native", a, label)\n' + old +
           '\n\t_k6_c_stream("c-target-restore", b, label)')
    return replace(source, old, new) + C_HELPER

def main():
    OUT.mkdir(exist_ok=False)
    manifest = {"status": "REVIEW_ONLY_NON_EXECUTABLE", "inputs": {}}
    for rel, transform in [(Q_PATH, q_overlay), (C_PATH, c_overlay)]:
        raw = (ROOT / rel).read_bytes()
        source = raw.decode("utf-8").replace("\r\n", "\n")
        output = transform(source)
        path = OUT / Path(rel).name
        payload = output.encode("utf-8")
        path.write_bytes(payload)
        diff = "".join(unified_diff(source.splitlines(keepends=True), output.splitlines(keepends=True), f"source/{rel}", f"overlay/{rel}"))
        path.with_suffix(".diff").write_text(diff, encoding="utf-8", newline="\n")
        manifest["inputs"][rel] = {
            "source_sha256": sha256(raw).hexdigest(),
            "overlay_sha256": sha256(payload).hexdigest(),
            "normalized_diff_sha256": sha256(path.with_suffix(".diff").read_bytes()).hexdigest(),
            "output": path.name,
        }
    (OUT / "SHA.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")

if __name__ == "__main__":
    main()
