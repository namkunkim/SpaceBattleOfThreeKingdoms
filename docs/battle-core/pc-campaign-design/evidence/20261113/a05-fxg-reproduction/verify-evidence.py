import hashlib
import json
from pathlib import Path
import sys

out = Path(sys.argv[1])
load = lambda path: json.loads(path.read_text(encoding="utf-8-sig"))
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
freeze = load(out / "fixture-freeze.json")
raw = load(out / "base-host-first-natural.json")
expected = [(0, 0), (1, 100), (2, 150)]
coord = lambda row: (row["tick"], row["clock_ms"])
def verdict(summary):
    return (
        coord(summary) == (2, 150)
        and summary["end_tick"] == 2 and summary["end_ms"] == 150
        and summary["over"] is True and summary["win"] is True
        and summary["reason"] == "annihilation"
    )

assert [coord(row["host_summary"]) for row in raw["frames"]] == expected
assert all(row["owner_summary"]["summary"] == row["host_summary"] for row in raw["frames"])
assert not any(row["command_log"] or row["queue"] for row in raw["frames"])
base_summary = raw["frames"][-1]["host_summary"]
assert verdict(base_summary)
assert not verdict(dict(base_summary, clock_ms=200, end_ms=200))

records = []
for variant in ("base", "j210"):
    h = load(out / f"{variant}-headless-result.json")
    r = load(out / f"{variant}-replay-result.json")
    assert h["ok"] and r["ok"]
    assert h["summary"] == r["summary"] and h["events"] == r["events"]
    assert verdict(h["summary"])
    assert sum(event["kind"] == "battle_end" for event in h["events"]) == 1
    if variant == "base":
        assert h["summary"] == base_summary and h["events"] == raw["events"]
    for lane, result, key in (("headless", h, "input_file_sha256"), ("replay", r, "replay_file_sha256")):
        binding = freeze["cases"][variant][lane]
        assert result["meta"]["input_sha256"] == binding["adapter_hash_of_reparsed_input"]
        assert result["meta"][key] == binding["file_sha256"] == sha(out / binding["file"])
    for speed in (1, 2, 4) if variant == "base" else (1,):
        for pause in (0, 1) if variant == "base" else (0,):
            for lane in ("host", "headless", "replay"):
                case = f"{variant}-{lane}-x{speed}-p{pause}"
                folder = out / "matrix-r2" / case
                data = load(folder / "ticks.json")
                result = load(folder / "result.json")
                binding = freeze["cases"][variant][lane]
                assert result["summary"] == h["summary"] and result["events"] == h["events"], case
                assert data["advance_calls"] == 2, case
                rows = data["rows"]
                assert [coord(row["summary"]) for row in rows if row["stage"] in ("initial", "after")] == expected, case
                permits = [row for row in rows if row["stage"] == "permit"]
                assert [(row["wall_ms"], row["speed"], row["permits"], row["advance_calls"]) for row in permits] == [(100 / speed, speed, 1, n) for n in range(2)], case
                holds = [row for row in rows if row["stage"] == "mid_pause"]
                terminal = [row for row in rows if row["stage"] == "terminal_pause"]
                resumes = [row for row in rows if row["stage"] == "terminal_resume"]
                assert len(holds) == len(terminal) == 2 * pause and len(resumes) == pause, case
                for row in holds + terminal:
                    count = 1 if row in holds else 2
                    assert (row["wall_ms"], row["speed"], row["permits"], row["advance_calls"]) == (250, 0, 0, count), case
                    assert coord(row["summary"]) == expected[count], case
                for row in resumes:
                    assert row["permits"] == 1 and row["advance_calls"] == 2 and verdict(row["summary"]), case
                if lane == "host":
                    assert result["prepare"]["ok"] and result["file_sha256"] == binding["file_sha256"], case
                    assert result["input_sha256"] == binding["adapter_hash_of_reparsed_input"], case
                    for row in result["observations"]:
                        assert row["owner"] == row["host"], case
                        assert f'Clock {row["owner"]["clock_ms"]} ms' in row["display"], case
                else:
                    assert result["meta"] == (h if lane == "headless" else r)["meta"], case
                records.append({"case": case, "result_sha256": sha(folder / "result.json"), "ticks_sha256": sha(folder / "ticks.json")})
assert len(records) == 21
for lane in ("host", "headless", "replay"):
    base = freeze["cases"]["base"][lane]
    moved = freeze["cases"]["j210"][lane]
    assert base["ally"] == [400, 600] and base["foe"] == [450, 600]
    assert moved["ally"] == [420, 600] and moved["foe"] == [470, 600]
    for key in ("file_sha256", "adapter_hash_of_reparsed_input", "canonical_input_sha256"):
        assert base[key] != moved[key]
print(json.dumps({"status": "preparatory experiment verified", "rejected_terminal_200": True, "runs": records}, indent=2))

