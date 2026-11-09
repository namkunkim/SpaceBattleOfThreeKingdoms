"""Source-only v3 adapter for one pinned, mixed C stdout stream."""
import hashlib
import json
import struct

from c_actual_extension_raw_v2 import case_base, plain, read_pinned
from c_actual_extension_case_v1 import check_case, same
from c_raw_overlay_mapping import PREFIX as BASE_PREFIX, phase_ids
from c_raw_overlay_mapping_v2 import A, B, evidence
from c_raw_v4_semantic_adapter import collect_case
from c_side1_pipeline_v9 import check_case as check_v9
from c_side1_semantics_v8 import decode, mapping, replace_at, typed
from legacy_autoresolve_oracle import need, unique

EXTRA_PREFIX = b"K6_C_EXTENSION "


def strict(a, b):
    """Type, metadata and order preserving Variant comparison."""
    if type(a) is not type(b):
        return False
    if type(a) is tuple:
        return len(a) == len(b) and all(strict(x, y) for x, y in zip(a, b))
    if type(a) is float:
        return struct.pack("<d", a) == struct.pack("<d", b)
    return a == b


def split_stdout(raw, receipt):
    """Retain exact offsets, hashes and common provenance for both prefixes."""
    base = []
    supplement = []
    offset = 0
    for line in raw.splitlines(keepends=True):
        if line.startswith(BASE_PREFIX):
            need(line.endswith(b"\n"), "unterminated base record")
            base.append((offset, hashlib.sha256(line).hexdigest()))
        elif line.startswith(EXTRA_PREFIX):
            need(line.endswith(b"\n"), "unterminated supplement record")
            row = json.loads(line[len(EXTRA_PREFIX):], object_pairs_hook=unique)
            need(set(row) == {"version", "ordinal", "base_ordinal_next", "case", "event", "payload_hex"},
                 "supplement record schema")
            need(type(row["base_ordinal_next"]) is int and row["base_ordinal_next"] == len(base),
                 "mixed stream ordinal")
            need(type(row["ordinal"]) is int and row["ordinal"] == len(supplement),
                 "supplement global ordinal")
            row["variant"] = mapping(decode(row.pop("payload_hex")))
            row["provenance"] = dict(offset=offset, line_sha=hashlib.sha256(line).hexdigest(),
                **{key: receipt[key] for key in ("lane", "pid", "created", "run_id", "raw_sha")})
            supplement.append(row)
        elif b"K6_C_" in line:
            raise ValueError("unexpected C record prefix")
        offset += len(line)
    need(base and supplement, "missing mixed stream")
    return base, supplement


def original_variant(rows, event, actor, phase=None):
    found = [row for row in rows if row["event"] == event and row["actor"] == actor
             and (phase is None or row["phase"] == phase)]
    need(len(found) == 1, "base typed boundary")
    return mapping(decode(found[0]["payload_hex"]))


def typed_checks(segment, extra, control):
    first = phase_ids(control["case"])[0]
    primary = original_variant(segment, "restore-request", B, first)
    mutation = extra[1]["variant"]
    before_hex = typed(mutation["packet_before"], 4, "before packet")
    before = decode(before_hex)
    need(before_hex == typed(primary["packet_raw"], 4, "primary bytes")
         and strict(before, primary["packet"]), "exact primary packet")
    zero = decode(control["mutation_zero_hex"])
    path = ["detection", "contacts", 0, control["mutation_id"], "pos"]
    changed = replace_at(before, path, zero)
    need(not strict(before, changed), "typed mutation no-op")
    after = decode(typed(mutation["packet_after"], 4, "after packet"))
    need(strict(after, changed), "typed packet mutation scope")
    for role, actor in (("source", A), ("target", B)):
        anchor = original_variant(segment, "alias-before", actor)["state"]
        before = mutation[role + "_before"]
        after = mutation[role + "_after"]
        need(strict(anchor, before) and strict(before, after), "typed alias state " + role)
    events = control["ordered_events_hex"]
    need(type(events) is list and len(events) == len(extra) - 3, "oracle suffix event coverage")
    for row, expected_hex in zip(extra[3:], events):
        payload = row["variant"]
        expected = decode(expected_hex)
        for field in ("before", "after", "all", "events", "fingerprint"):
            need(strict(payload["source_" + field], payload["target_" + field]),
                 "typed suffix " + field)
        for role in ("source", "target"):
            outside = mapping(mapping(payload[role + "_all"])["outside"])
            need(strict(payload[role + "_events"], expected), "independent suffix events")
            # _all deliberately calls _plain on events, erasing Array metadata.
            need(same(plain(outside["events"]), plain(expected)), "legacy pre-drain events")


def verify_lane(stdout_path, receipt_path, receipt_sha, producer_sha, oracle_path, oracle_sha):
    oracle = json.loads(read_pinned(oracle_path, oracle_sha, 20_000_000), object_pairs_hook=unique)
    need(type(oracle) is dict and type(oracle.get("cases")) is list and bool(oracle["cases"]),
         "unresolved independent dynamic oracle")
    receipt = json.loads(read_pinned(receipt_path, receipt_sha, 65_536), object_pairs_hook=unique)
    for key in ("run_id", "lane", "pid", "created", "raw_sha"):
        need(same(oracle[key], receipt[key]), "oracle mixed run provenance")
    provenance = oracle["provenance"]
    need(all(type(provenance.get(key)) is str and provenance[key] for key in ("source", "method")),
         "unresolved independent dynamic oracle")
    need(type(provenance.get("sha256")) is str and len(provenance["sha256"]) == 64,
         "missing independent source digest")
    raw = read_pinned(stdout_path, receipt["raw_sha"], 96_000_000)
    offsets, extra = split_stdout(raw, receipt)
    rows = evidence(stdout_path, receipt, producer_sha)
    need(offsets == [(r["offset"], r["line_sha"]) for r in rows], "base split drift")
    expected = list(dict.fromkeys((row["seed"], row["case"]) for row in rows))
    need(same([[control["seed"], control["case"]] for control in oracle["cases"]],
              [list(case) for case in expected]), "oracle case coverage")
    start = 0
    for control in oracle["cases"]:
        seed, case = control["seed"], control["case"]
        base = case_base(rows, seed, case, start)
        count = len(base["extension_anchors"])
        observed = extra[start:start + count]
        need(len(observed) == count, "missing case supplement")
        segment = [row for row in rows if (row["seed"], row["case"]) == (seed, case)]
        capture = collect_case(rows, seed, case)
        capture["reported_contact_id"] = control["mutation_id"]
        check_v9(capture, control["case_pin_path"], control["case_pin_sha"], seed=seed, case=case)
        need(same(base["roster"], control["roster"]), "independent roster mismatch")
        books = base["primary_packet"]["detection"]["contacts"]
        keys = [sorted(book) for book in books]
        need(same(keys, control["contact_keys"]), "independent contact keys")
        required = [entry for peer in ("source", "packet") for entry in
                    ([[peer, -1, None]] + [entry for side, ids in enumerate(keys) for entry in
                    ([[peer, side, None]] + [[peer, side, ident] for ident in ids])])]
        need(same(required, control["identity_pairs"]), "independent identity pair coverage")
        typed_checks(segment, observed, control)
        projected = []
        for row in observed:
            payload = {key: plain(value) for key, value in row["variant"].items()}
            for key in ("packet_before", "packet_after"):
                if key in payload:
                    payload[key] = plain(decode(payload[key]))
            projected.append(row | {"payload": payload})
        check_case(projected, control | {"mutation_zero": plain(decode(control["mutation_zero_hex"]))}, base)
        start += count
    need(start == len(extra), "extra supplement rows")
    return start

