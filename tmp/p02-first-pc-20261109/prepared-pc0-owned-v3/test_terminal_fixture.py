"""Hand-authored PC0 trace: run the production verifier and mutate one fact per case."""
from copy import deepcopy
import sys

sys.dont_write_bytecode = True
from verify import verify_battle

TIMEOUT_TICK, TIMEOUT_MS = 12010, 1200950


def fixture():
    trace = []

    def add(kind, tick, sim_ms, mono, **data):
        trace.append(dict(kind=kind, tick=tick, sim_ms=sim_ms, mono_ms=mono,
                          data=data, seq=len(trace) + 1))

    def phase(name, epoch, point, tick, ms, mono, state, screen, **details):
        add("pc0_phase", tick, ms, mono, phase=name, epoch=epoch, point=point,
            sample_ms=mono, sim_id="100", host_id="200", speed=1, screen=screen,
            focused=True, placing=name == "placing", state=state,
            log_size=0 if name == "placing" else 1, **details)

    roster = [
        dict(side=0, id=1, sq="RC-LIU-SQ-01", faction="liu_bei", is_flag=True, control="direct"),
        dict(side=0, id=2, sq="RC-LIU-SQ-02", faction="liu_bei", is_flag=False, control="direct"),
        dict(side=0, id=3, sq="RC-LIU-SQ-03", faction="liu_bei", is_flag=False, control="direct"),
        dict(side=0, id=4, sq="RC-SUN-SQ-01", faction="sun_quan", is_flag=False, control="delegate"),
        dict(side=0, id=5, sq="RC-SUN-SQ-02", faction="sun_quan", is_flag=False, control="delegate"),
        dict(side=0, id=6, sq="RC-SUN-SQ-03", faction="sun_quan", is_flag=False, control="delegate"),
    ]
    add("session_start", 0, 0, 500, profile="red-cliffs-208-rt",
        profile_path="res://data/profiles/red_cliffs_rt.json", seed=777, difficulty="입문", hz=10)
    phase("placing", 2, 1, 0, 0, 1000, "play", "", roster=roster)
    phase("placing", 2, 2, 0, 0, 3000, "play", "")
    add("pc0_phase_exit", 0, 0, 3600, phase="placing", epoch=2, two_samples=True)
    add("pc0_advance", 1, 100, 3700, sim_id="100", speed=1, **{"from": "placing", "from_epoch": 2})
    add("right_press", 2, 200, 3800, state="play", selected=[1], emulated=False)
    add("right_release", 2, 200, 3801, dragging=False, selected=[1], world=[400, 600])
    cmd = dict(kind="move", ids=[1], point=[400, 600], target_id=-1)
    raw = dict(cmd, tick=2, side=0, args={})
    probe = dict(sim_id="100", focus=True, selected=[1], edge=20, field=[1000, 1000])
    add("command_request", 2, 200, 3801, command=cmd, pc0=dict(probe, last=None, log_size=0),
        fleets=[dict(id=1, pos=[200, 600], has_move=False, move_to=[0, 0])])
    add("command_applied", 2, 200, 3801, command=cmd, pc0=dict(probe, last=raw, log_size=1),
        fleets=[dict(id=1, pos=[200, 600], has_move=True, move_to=[400, 600])])
    add("snapshot", 10, 1000, 4600, fleets=[dict(id=1, pos=[220, 600])])
    phase("paused", 4, 1, 11, 1100, 4700, "pause", "pause")
    phase("paused", 4, 2, 11, 1100, 6700, "pause", "pause")
    add("pc0_phase_exit", 11, 1100, 7300, phase="paused", epoch=4, two_samples=True)
    add("pc0_advance", 12, 1200, 7400, sim_id="100", speed=1, **{"from": "paused", "from_epoch": 4})
    terminal_at = 1207150
    result = dict(win=False, reason="time_limit", tick=TIMEOUT_TICK, t_s=1200.95,
                  conditions=dict(alliance=[], foe=[]), limited=False)
    add("core_event", TIMEOUT_TICK, TIMEOUT_MS, terminal_at,
        event=dict(kind="battle_end", value="time_limit", tick=TIMEOUT_TICK))
    add("battle_end", TIMEOUT_TICK, TIMEOUT_MS, terminal_at, win=False, reason="time_limit", result=result)
    phase("terminal", 6, 1, TIMEOUT_TICK, TIMEOUT_MS, terminal_at + 1, "play", "")
    add("pc0_end_screen", TIMEOUT_TICK, TIMEOUT_MS, terminal_at + 1601,
        state="end", screen="result", phase="terminal", epoch=6, host_id="200",
        sim_id="100", focused=True, sample_ms=terminal_at + 1601)
    phase("terminal", 6, 2, TIMEOUT_TICK, TIMEOUT_MS, terminal_at + 2001, "end", "result")
    return trace


def get(trace, kind, phase=None, point=None):
    row, = [r for r in trace if r["kind"] == kind and
            (phase is None or r["data"]["phase"] == phase) and
            (point is None or r["data"]["point"] == point)]
    return row


def accepted(trace, label):
    summary, _ = verify_battle(trace)
    assert (summary["tick"], summary["sim_ms"]) == (TIMEOUT_TICK, TIMEOUT_MS)
    print("PASS", label)


def rejected(trace, label):
    try:
        verify_battle(trace)
    except (AssertionError, ValueError):
        print("PASS", label)
        return
    raise AssertionError("Accepted bad trace: " + label)


def main():
    normal = fixture()
    accepted(normal, "normal 1.6-second play-to-result transition")
    delayed = deepcopy(normal)
    end = get(delayed, "pc0_end_screen")
    second = get(delayed, "pc0_phase", "terminal", 2)
    second["data"].update(state="play", screen="")
    end["seq"], second["seq"] = second["seq"], end["seq"]
    end["mono_ms"] = end["data"]["sample_ms"] = second["mono_ms"] + 500
    delayed.sort(key=lambda row: row["seq"])
    accepted(delayed, "same result screen after the second frozen sample")
    for field in ("tick", "sim_ms"):
        modified = deepcopy(normal)
        get(modified, "pc0_phase", "terminal", 2)[field] += 1
        rejected(modified, "terminal advances " + field)
    for field in ("sim_id", "host_id", "epoch"):
        modified = deepcopy(normal)
        get(modified, "pc0_phase", "terminal", 2)["data"][field] = "swapped"
        rejected(modified, "terminal sample changes " + field)
    rejected([r for r in normal if r["kind"] != "pc0_end_screen"], "missing end-screen marker")
    modified = deepcopy(normal)
    get(modified, "pc0_end_screen")["data"]["screen"] = ""
    rejected(modified, "end state without visible result HUD state")
    modified = deepcopy(normal)
    get(modified, "pc0_phase", "paused", 2)["data"]["screen"] = "settings_pause"
    rejected(modified, "pause HUD changes between observations")


if __name__ == "__main__":
    main()
