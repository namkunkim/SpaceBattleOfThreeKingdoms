"""Supplemental C case checks over independently decoded, typed raw rows.

The caller must bind both streams and the independently pinned case control
to the same approved run before invoking this case API.
"""

from copy import deepcopy
import math


def require(ok, reason):
    if not ok:
        raise ValueError(reason)


def same(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return len(a) == len(b) and all(
            any(same(ka, kb) and same(va, vb) for kb, vb in b.items())
            for ka, va in a.items()
        )
    if isinstance(a, (list, tuple)):
        return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    if isinstance(a, float):
        return math.isfinite(a) and math.isfinite(b) and a.hex() == b.hex()
    return a == b


def check_case(rows, control, base):
    """Validate a single independently controlled case after raw decoding.

    base comes from the verified v4/v9 join, including anchor ordinals,
    typed packet, projected configuration and actual primary/repair receipts.
    Vector2 is represented by its decoder-native typed value in both inputs.
    """
    for name in ("seed", "case", "source_id", "target_id"):
        require(same(base[name], control[name]), "case control identity")
    require(same(base["config"], control["config"]), "case control config")
    require(base["primary_result"] is True and base["repair_result"] is True, "restore result")
    period = control["period"]
    require(type(period) is int and period > 0, "suffix period")
    kinds = ["identity", "mutation", "identity"] + ["suffix"] * (period + 1)
    require(len(rows) == len(kinds), "extension row coverage")
    require(same([row["event"] for row in rows], kinds), "extension event order")
    require(same([row["base_ordinal_next"] for row in rows], base["extension_anchors"]), "base stream anchors")
    for index, row in enumerate(rows):
        require(same(row["version"], 1), "extension version")
        require(same(row["ordinal"], base["first_extension_ordinal"] + index), "extension ordinal")
        require(same(row["case"], {key: base[key] for key in ("seed", "case", "source_id", "target_id")}), "extension case")
    for index, receipt in ((0, "primary"), (2, "repair")):
        identity = rows[index]["payload"]
        require(same(identity["request_id"], base[receipt + "_request"]), "identity request")
        require(same(identity["tick"], base["tick"]), "identity tick")
        expected = [[*pair, False] for pair in control["identity_pairs"]]
        # Godot dictionary insertion order is immaterial for identity coverage.
        actual = identity["pairs"]
        require(len(actual) == len(expected) and all(
            sum(same(pair, seen) for seen in actual) == 1 for pair in expected
        ), "identity detach")
    mutation = rows[1]["payload"]
    require(same(mutation["request_id"], base["primary_request"]), "mutation request")
    require(same(mutation["tick"], base["tick"]), "mutation tick")
    require(same(mutation["id"], control["mutation_id"]), "mutation id")
    packet = mutation["packet_before"]
    require(same(packet, base["primary_packet"]), "mutation initial packet")
    expected_packet = deepcopy(packet)
    record = expected_packet["detection"]["contacts"][0][control["mutation_id"]]
    require(not same(record["pos"], control["mutation_zero"]), "mutation no-op")
    record["pos"] = control["mutation_zero"]
    require(same(expected_packet, mutation["packet_after"]), "packet mutation scope")
    for actor in ("source", "target"):
        before, after = mutation[actor + "_before"], mutation[actor + "_after"]
        require(same(before, base[actor + "_alias_state"]), "mutation state anchor")
        require(same(before, after), "mutation leaked into live state")
    previous = base["repair_inputs"]
    for index, row in enumerate(rows[3:]):
        suffix = row["payload"]
        require(same(suffix["index"], index), "suffix index")
        for actor in ("source", "target"):
            require(same(suffix[actor + "_tick"], base["tick"] + index + 1), "suffix tick")
            require(same(suffix[actor + "_before"], previous[actor]), "suffix input continuity")
        for field in ("before", "after", "all", "events", "fingerprint"):
            require(same(suffix["source_" + field], suffix["target_" + field]), "suffix " + field)
        # Service suffix issues no explicit command and starts from a clean queue.
        for actor in ("source", "target"):
            before = suffix[actor + "_before"]
            after = suffix[actor + "_after"]
            require(same(before["queue"], []) and same(after["queue"], []), "suffix queue")
            require(same(before["command_log"], after["command_log"]), "suffix command mutation")
        previous = {actor: suffix[actor + "_after"] for actor in ("source", "target")}
