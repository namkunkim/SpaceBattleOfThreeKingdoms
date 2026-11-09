"""Read a separately approved actual C supplement and bind it to base rows."""
import hashlib
import json
from pathlib import Path

from c_actual_extension_case_v1 import check_case, same
from c_raw_overlay_mapping import phase_ids
from c_raw_overlay_mapping_v2 import A, B, evidence
from c_raw_v4_semantic_adapter import collect_case
from c_side1_semantics_v8 import decode, mapping, typed
from legacy_autoresolve_oracle import need, unique

PREFIX = b"K6_C_EXTENSION "


def plain(node):
    tag, metadata, value = node
    if tag == 27:
        result = {}
        for key, item in value:
            index = plain(key)
            need(index not in result, "ambiguous dictionary key")
            result[index] = plain(item)
        return result
    if tag == 28:
        return [plain(item) for item in value]
    if tag in (0, 1, 2, 3, 4, 5):
        return value
    if tag == 21:
        return ("StringName", value)
    raise ValueError("unsupported supplemental Variant")


def read_pinned(path, digest, limit):
    need(type(digest) is str and len(digest) == 64, "missing external SHA")
    with Path(path).open("rb") as stream:
        data = stream.read(limit + 1)
    need(0 < len(data) <= limit, "missing or oversized evidence")
    need(hashlib.sha256(data).hexdigest() == digest, "external SHA mismatch")
    return data


def read_extra(path, receipt):
    content = read_pinned(path, receipt["extension_sha256"], 96_000_000)
    rows = []
    for line in content.splitlines():
        need(line.startswith(PREFIX), "supplement stream record prefix")
        row = json.loads(line[len(PREFIX):], object_pairs_hook=unique)
        need(set(row) == {"version", "ordinal", "base_ordinal_next", "case", "event", "payload_hex"},
             "supplement record schema")
        raw = mapping(decode(row.pop("payload_hex")))
        payload = {key: plain(value) for key, value in raw.items()}
        for field in ("packet_before", "packet_after"):
            if field in raw:
                payload[field] = plain(decode(typed(raw[field], 4, field)))
        row["payload"] = payload
        rows.append(row)
    return rows


def case_base(rows, seed, case, start):
    segment = [row for row in rows if (row["seed"], row["case"]) == (seed, case)]

    def get(event, actor, phase=None):
        found = [row for row in segment if row["event"] == event and row["actor"] == actor
                 and (phase is None or row["phase"] == phase)]
        need(len(found) == 1, "base boundary missing or ambiguous")
        row = found[0]
        return row, mapping(decode(row["payload_hex"]))

    capture = collect_case(rows, seed, case)
    primary, _, _, repaired, repaired_repeat = phase_ids(case)
    source, first = get("source-after", A, primary)
    target, _ = get("restore-result", B, primary)
    repair, repair_data = get("source-after", A, repaired)
    _, repair_source = get("source-after", A, repaired_repeat)
    _, repair_target = get("restore-result", B, repaired_repeat)
    alias_a, alias_source = get("alias-before", A)
    alias_b, alias_target = get("alias-before", B)
    scope, _ = get("scope-end", B)

    def inputs(payload):
        outside = mapping(mapping(payload["state"])["outside"])
        return {key: plain(outside[key]) for key in ("command_log", "queue")}

    config = [plain(mapping(decode(row["payload_hex"]))["detection_config"])
              for row in segment if row["event"] == "eval"]
    need(bool(config) and all(same(item, config[0]) for item in config), "effective config drift")
    period = config[0]["eval_period_s"] * 10
    need(period == 10, "source-derived effective period")
    roster = plain(mapping(decode(capture["source_first"]))["roster"])
    return dict(roster=roster, seed=seed, case=case, source_id=source["sim_id"], target_id=target["sim_id"],
                config=config[0], tick=source["tick"], first_extension_ordinal=start,
                extension_anchors=[source["stream_ordinal"] + 1, alias_b["stream_ordinal"] + 1,
                                   repair["stream_ordinal"] + 1] + [scope["stream_ordinal"] + 1] * (int(period) + 1),
                primary_request=plain(first["request_id"]), repair_request=plain(repair_data["request_id"]),
                primary_result=capture["phases"]["first"]["result"]["ok"],
                repair_result=capture["phases"]["repaired"]["result"]["ok"],
                primary_packet=plain(decode(capture["phases"]["first"]["packet_hex"])),
                source_alias_state=plain(alias_source["state"]), target_alias_state=plain(alias_target["state"]),
                repair_inputs={"source": inputs(repair_source), "target": inputs(repair_target)})


def verify_lane(base_path, extension_path, receipt_path, receipt_sha, producer_sha, oracle_path, oracle_sha):
    """The three SHA arguments must come from independent approval."""
    oracle = json.loads(read_pinned(oracle_path, oracle_sha, 20_000_000), object_pairs_hook=unique)
    receipt = json.loads(read_pinned(receipt_path, receipt_sha, 65_536), object_pairs_hook=unique)
    need(oracle["lane"] == receipt["lane"] and oracle["run_id"] == receipt["run_id"], "oracle lane/run binding")
    need(oracle["provenance"] and oracle["cases"], "unresolved dynamic oracle")
    rows = evidence(base_path, receipt, producer_sha)
    extra = read_extra(extension_path, receipt)
    expected = list(dict.fromkeys((row["seed"], row["case"]) for row in rows))
    need([(control["seed"], control["case"]) for control in oracle["cases"]] == expected, "oracle case coverage")
    start = 0
    for control in oracle["cases"]:
        base = case_base(rows, control["seed"], control["case"], start)
        count = len(base["extension_anchors"])
        observed = extra[start:start + count]
        need(same(base["roster"], control["roster"]), "independent roster mismatch")
        books = base["primary_packet"]["detection"]["contacts"]
        keys = [[ident for ident in book] for book in books]
        need(same([sorted(side) for side in keys], control["contact_keys"]), "independent contact keys")
        expected_pairs = [
            pair for peer in ("source", "packet")
            for pair in ([[peer, -1, None]] + [
                entry for side, ids in enumerate(keys)
                for entry in ([[peer, side, None]] + [[peer, side, ident] for ident in ids])
            ])
        ]
        need(same(control["identity_pairs"], expected_pairs), "independent identity pair coverage")
        check_case(observed, control | {"mutation_zero": plain(decode(control["mutation_zero_hex"]))}, base)
        events = control["ordered_events_hex"]
        need(type(events) is list and len(events) == count - 3, "oracle suffix event coverage")
        for row, expected_events in zip(observed[3:], events):
            expected_drain = plain(decode(expected_events))
            for actor in ("source", "target"):
                payload = row["payload"]
                need(same(payload[actor + "_events"], expected_drain), "independent suffix event mismatch")
                need(same(payload[actor + "_all"]["outside"]["events"], expected_drain), "suffix drain/state mismatch")
        start += count
    need(start == len(extra), "supplement trailing rows")
    return start


