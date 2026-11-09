"""Mechanical PC0 evidence checks. Visual and attribution checks still require independent review."""
import json
import math
from pathlib import Path
import sys

PREP = Path(__file__).resolve().parent
RUN = PREP.parent / "run-01"
EXPECTED = json.loads((PREP / "oracle.json").read_text(encoding="utf-8"))


def only(items):
    items = list(items)
    assert len(items) == 1, len(items)
    return items[0]


def rows(path):
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line]


def kinds(trace, kind):
    return [row for row in trace if row["kind"] == kind]


def state(row):
    return row["tick"], row["sim_ms"]


def same_xy(a, b, tolerance):
    return math.dist(a, b) <= tolerance


def fleet(row, fid, key="fleets"):
    return only(f for f in row["data"][key] if f["id"] == fid)


def stable(trace, phase):
    a, b = [r for r in kinds(trace, "pc0_phase") if r["data"]["phase"] == phase]
    assert [a["data"]["point"], b["data"]["point"]] == [1, 2]
    fields = ("epoch", "sim_id", "host_id", "placing", "speed", "log_size")
    if phase != "terminal":
        fields += ("state", "screen")
    for field in fields:
        assert a["data"][field] == b["data"][field], (phase, field)
    assert b["data"]["sample_ms"] - a["data"]["sample_ms"] >= 2000
    assert a["data"]["focused"] and b["data"]["focused"]
    assert state(a) == state(b)
    return a, b


def verify_battle(trace):
    placing, end_place = stable(trace, "placing")
    paused, end_pause = stable(trace, "paused")
    terminal, end_terminal = stable(trace, "terminal")
    starts = only(kinds(trace, "session_start"))["data"]
    for field, value in EXPECTED["session"].items():
        assert starts[field] == value, field
    assert state(placing) == (0, 0)
    observed = [{k: f[k] for k in ("side", "id", "sq", "faction", "is_flag", "control")}
                for f in placing["data"]["roster"]]
    assert observed == EXPECTED["roster"], observed
    sim = placing["data"]["sim_id"]
    assert all(r["data"]["sim_id"] == sim for r in (paused, terminal))
    advances = kinds(trace, "pc0_advance")
    for phase, stop in (("placing", end_place), ("paused", end_pause)):
        advance = only(r for r in advances if r["data"]["from"] == phase)
        end = only(r for r in kinds(trace, "pc0_phase_exit") if r["data"]["phase"] == phase)
        assert end["data"]["two_samples"] and end["data"]["epoch"] == stop["data"]["epoch"]
        assert advance["data"]["from_epoch"] == stop["data"]["epoch"]
        assert advance["data"]["sim_id"] == sim and advance["data"]["speed"] == 1
        assert stop["seq"] < end["seq"] < advance["seq"]
        assert all(x > y for x, y in zip(state(advance), state(stop)))

    fid = EXPECTED["flag_id"]
    request = only(r for r in kinds(trace, "command_request") if r["data"]["command"]["kind"] == "move")
    applied = only(r for r in kinds(trace, "command_applied") if r["data"]["command"]["kind"] == "move")
    assert end_place["seq"] < request["seq"] < applied["seq"] < paused["seq"]
    q, p = request["data"], applied["data"]
    cmd = p["pc0"]["last"]
    assert q["command"] == p["command"] and cmd["kind"] == "move"
    assert q["pc0"]["sim_id"] == p["pc0"]["sim_id"] == sim
    assert q["pc0"]["focus"] and p["pc0"]["focus"]
    assert q["pc0"]["selected"] == p["pc0"]["selected"] == cmd["ids"] == q["command"]["ids"] == [fid]
    assert p["pc0"]["log_size"] == q["pc0"]["log_size"] + 1
    assert cmd["side"] == 0 and cmd["target_id"] == -1
    assert request["tick"] == applied["tick"] == cmd["tick"]
    goal = q["command"]["point"]
    press = only(r for r in kinds(trace, "right_press") if end_place["seq"] < r["seq"] < request["seq"])
    release = only(r for r in kinds(trace, "right_release") if press["seq"] < r["seq"] < request["seq"])
    assert press["data"]["state"] == "play" and not press["data"]["emulated"]
    assert press["data"]["selected"] == release["data"]["selected"] == [fid]
    assert not release["data"]["dragging"] and release["tick"] == request["tick"]
    assert goal == cmd["point"] and same_xy(release["data"]["world"], goal, 0.05)
    edge = q["pc0"]["edge"]
    assert all(edge < x < bound - edge for x, bound in zip(goal, q["pc0"]["field"]))
    before, after = fleet(request, fid), fleet(applied, fid)
    assert not before["has_move"] and after["has_move"] and before["move_to"] != after["move_to"]
    assert same_xy(after["move_to"], goal, 0.05)
    assert not kinds(trace, "command_blocked")
    related = (r for r in kinds(trace, "core_event") if r["data"]["event"]["kind"] == "rejected"
               and r["data"]["event"]["tick"] == cmd["tick"] and r["seq"] >= request["seq"])
    assert not list(related)
    start_pos = before["pos"]
    direction = [x - y for x, y in zip(goal, start_pos)]
    moved = None
    for row in kinds(trace, "snapshot"):
        if not applied["seq"] < row["seq"] < paused["seq"] or row["sim_ms"] > applied["sim_ms"] + 10000:
            continue
        position = fleet(row, fid)["pos"]
        delta = [x - y for x, y in zip(position, start_pos)]
        if math.hypot(*delta) >= 1 and sum(a*b for a,b in zip(direction, delta)) > 0:
            moved = row
            break
    assert moved is not None
    assert not [r for r in kinds(trace, "command_request") if applied["seq"] < r["seq"] < moved["seq"]]
    assert all(r["data"]["speed"] == 1 and r["data"]["slow"] == 1 for r in kinds(trace, "ui_state")
               if r["seq"] >= placing["seq"])
    summary = only(kinds(trace, "battle_end"))
    event = only(r for r in kinds(trace, "core_event") if r["data"]["event"]["kind"] == "battle_end")
    screen = only(kinds(trace, "pc0_end_screen"))
    assert event["seq"] < summary["seq"] < terminal["seq"]
    assert state(summary) == state(event) == state(terminal) == state(end_terminal) == state(screen)
    first, second, shown = (row["data"] for row in (terminal, end_terminal, screen))
    assert shown["state"] == "end" and shown["screen"] == "result" and shown["focused"]
    assert shown["phase"] == "terminal"
    assert all(shown[key] == first[key] for key in ("host_id", "sim_id", "epoch"))
    assert first["state"] in ("play", "end") and second["state"] in ("play", "end")
    assert not (first["state"] == "end" and second["state"] == "play")
    assert terminal["seq"] < screen["seq"] and first["sample_ms"] <= shown["sample_ms"]
    # The phase row precedes the screen row when both are written in the same frame.
    if screen["seq"] < end_terminal["seq"]:
        assert second["state"] == "end" and second["screen"] == "result"
        assert shown["sample_ms"] <= second["sample_ms"]
    else:
        assert second["sample_ms"] <= shown["sample_ms"]
    result = summary["data"]["result"]
    why, win = summary["data"]["reason"], summary["data"]["win"]
    assert event["data"]["event"]["tick"] == summary["tick"]
    assert event["data"]["event"]["value"] == result["reason"] == why
    assert result["win"] == win and result["tick"] == summary["tick"]
    assert result["t_s"] * 1000 == summary["sim_ms"] or math.isclose(result["t_s"] * 1000, summary["sim_ms"])
    a, f = result["conditions"]["alliance"], result["conditions"]["foe"]
    if a and f:
        assert why == "simultaneous" and not win
    elif a:
        assert why == a[0] and not win
    elif f:
        assert why == f[0] and win
    elif result["limited"]:
        assert why == "alliance_escaped" and win
    else:
        assert why == "time_limit" and not win
    expected = EXPECTED["deadline"]
    if why == "time_limit":
        assert state(summary) == (expected["first_tick"], expected["first_ms"])
    else:
        assert state(summary) <= (expected["first_tick"], expected["first_ms"])
    assert summary["tick"] % expected["period"] == 0 and summary["sim_ms"] == (summary["tick"] - 1) * 100 + 50
    return summary, [placing, request, applied, moved, paused, screen]


def verify_route(summary):
    log = (RUN / "product.log").read_text(encoding="utf-8")
    route = [json.loads(line.removeprefix("PC0_LINK ")) for line in log.splitlines() if line.startswith("PC0_LINK ")]
    anchor = only(r for r in route if r["kind"] == "clock_anchor")
    nonnull = [r for r in route if r["payload"] is not None]
    assert [r["kind"] for r in nonnull] == ["publish", "consume", "show_result_enter", "show_result_display"]
    assert len([r for r in route if r["kind"] == "publish"]) == 1
    assert all(r["kind"] in ("clock_anchor", "consume") and r["mono_ms"] <= nonnull[0]["mono_ms"]
               for r in route if r["payload"] is None)
    assert all(r["brief_null"] for r in nonnull)
    assert [r["queue_null"] for r in nonnull] == [False, True, True, True]
    outcome = nonnull[0]["payload"]
    assert all(r["payload"] == outcome and r["pid"] == anchor["pid"] for r in nonnull)
    r = summary["data"]["result"]
    for key in ("win", "reason", "t_s", "limited"):
        assert outcome[key] == r[key], key
    assert outcome["mode"] == "direct" and outcome["seed"] == 777 and outcome["difficulty"] == "입문"
    expected_kind = "alliance_limited" if r["limited"] else "alliance_win" if r["win"] else "cao_win"
    assert outcome["kind"] == expected_kind
    for side in ("alliance", "foe"):
        original, remaining = (r["cost"][side][k] for k in ("original", "remaining"))
        loss = (200 * (original - remaining) + original) // (2 * original) if original > 0 else 0
        assert outcome["loss_pct"][side] == min(100, max(0, loss))
    shown = nonnull[-1]["display"]
    assert shown["state"] == "result" and shown["visible"]
    assert shown["title"] == {"alliance_win": "연합 승리", "alliance_limited": "제한적 승리",
                              "cao_win": "조조 승리"}[outcome["kind"]]
    whole = int(outcome["t_s"])
    assert shown["time"] == f"{whole//60}분 {whole%60:02d}초"
    assert shown["loss_a"] == f'{outcome["loss_pct"]["alliance"]}%'
    assert shown["loss_f"] == f'{outcome["loss_pct"]["foe"]}%'
    assert all(shown[k] for k in ("title", "ending", "eyebrow", "regions"))
    return anchor, nonnull


def main():
    trace_paths = sorted((RUN / "appdata").rglob("battle-*.jsonl"))
    traces = {p: rows(p) for p in trace_paths}
    path = only(p for p, rs in traces.items() if kinds(rs, "battle_end"))
    trace = traces[path]
    assert all(r["seq"] == i for i, r in enumerate(trace, 1))
    summary, moments = verify_battle(trace)
    anchor, route = verify_route(summary)
    events = [line.split("\t") for line in (RUN / "product.os.tsv").read_text().splitlines()]
    member = only(r for r in events if r[2] == "member")
    assert int(member[3]) == anchor["pid"]
    assert only(r for r in events if r[2] == "exit")[3] == "0"
    assert only(r for r in events if r[2] == "cleanup")[3] == "0"
    assert [r[3] for r in events if r[2] == "witness"] == ["brief", "resume", "terminal", "map"]
    print(json.dumps({"trace": str(path), "anchor": anchor, "battle_sequences": [r["seq"] for r in moments],
                      "route": route, "terminal_tick": summary["tick"], "terminal_ms": summary["sim_ms"]},
                     ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
