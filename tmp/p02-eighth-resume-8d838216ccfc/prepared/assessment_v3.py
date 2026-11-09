"""Frozen pre-run assertion and typed-observation checks."""
from collections import Counter
import json
from pathlib import Path
import re

CLEAN_DEVIATION = "천하에서 오면 브리핑부터 (prologue)"
SUITE_COUNTS = {"battle_flow":23, "autoresolve":1, "p02_worker_adapter":59, "p02_viewer_events":148}

def expectation(job):
    case, lane, row = job["case_id"], job["lane"], job["row_id"]
    instrumented = lane == "instrumented"
    ids = []
    if case == "native":
        diff = job["exact_argv"][-1]
        ids = [f"{diff}/{s}" for s in ("effective","reinf-alias","auto-prepare","auto-effective","auto-view-prepare","auto-reinf-prepare")]
        for mode in ("direct","auto"):
            ids += [f"{diff}/{mode}/{s}" for s in ("0","1","10","100","viewer/0","viewer/1","viewer/10","viewer/100","reinf-before","reinf-first")]
    elif case == "deployment":
        ids = "confirmed-org-valid published-confirmed-org pre-action-native place-state same-tick-command typed-viewer-events trace-command-record next-tick-native".split()
    elif case == "poc":
        ids = ["poc/published", *(f"poc/{t}" for t in (0,1,10,100))]
    elif case == "alias":
        ids = [f"{cb}/{name}" for cb in ("density","cross-counter","synthetic")
               for name in ("prepared-seed","typed-effective","alias-reinf-combat","initial")]
        ids += ["synthetic/element-alias","synthetic/after-mutation-name-and-id","synthetic/after-mutation-state-events","invalid-org-auto-fallback"]
    elif case == "contract":
        for mode in ("direct","auto"):
            for seed in (-1,4294967296):
                suffix = f"{mode}/{seed}"
                ids.extend(("shape/" + suffix,"state/" + suffix))
                if instrumented:
                    ids.append("calls/" + suffix)
        ids.extend(("reject/invalid","reject/"))
    elif case in ("guard-active","mode-active"):
        ids = ["active-" + s for s in ("exact-rejection","identity","snapshot","error-visibility","next-tick","restart")]
        if instrumented:
            ids.extend("active-" + s for s in ("normal-counts","rejection-counts","recovery-counts"))
        if case == "mode-active":
            ids.append("active-mode-only")
    elif case == "invalid-brief":
        ids = ["legacy-invalid-brief"]
    elif case in ("guard-initial","mode-initial"):
        ids = ["initial-rejected","initial-returned-without-result"]
        if instrumented:
            ids.append("initial-counts")
    elif case == "retry":
        def sortie(prefix, opens):
            return [f"{prefix}/{b}/{s}" for b in (["open"] if opens else []) + ["mode","difficulty","sortie","skip"]
                    for s in ("enabled","pressed")] + [f"{prefix}/{s}" for s in ("brief-created","fixture-seed-only")]
        ids = sortie("terminal", not instrumented)
        if instrumented:
            ids += sortie("injected", True) + ["injected-reject","injected-valid-profile","retry-same-brief","retry-start-counts"]
        ids += ["started","joined","one-visible-outcome","poll-idempotent"]
    elif case in ("world-complete","world-cancel"):
        ids = [s + t for s in ("mode-auto","standard","sortie","skip") for t in ("-control","-pressed-once")]
        ids += ["world-real-scene","world-product-marker-card","sortie-brief","resolver-start"]
        ids += ["result-join","poll-idempotent"] if case == "world-complete" else ["stop-control","stop-pressed-once","cancel-join"]
    if ids:
        return {"kind":"json-assertions" if row in (17,18) else "probe-assertions","ids":ids}
    if row in (19,20,21):
        return {"kind":"suite-assertions","count":SUITE_COUNTS.get(case),
                "pending_exact_denominator":case not in SUITE_COUNTS,
                "duplicate_policy":"ordinal-indexed, exact pair sequence comparison",
                "allowed_failure":CLEAN_DEVIATION if case == "world-clean" else None}
    return {"kind":"external-gui","pending_evidence":True}

def read_checks(job, spec):
    kind = spec["kind"]
    if kind == "json-assertions":
        rows = json.loads(Path(job["raw"]).read_text(encoding="utf-8-sig"))
        return [(r["assertion"],r["ok"]) for r in rows]
    rows = []
    for line in Path(job["stdout"]).read_text(encoding="utf-8-sig").splitlines():
        if kind == "suite-assertions" and line.startswith("K6_SUITE_ASSERT "):
            label, ok = json.loads(line.removeprefix("K6_SUITE_ASSERT "))
            rows.append((label,ok))
        if kind == "probe-assertions" and line.startswith("ASSERT "):
            label, ok = line.removeprefix("ASSERT ").rsplit(" ",1)
            if ok not in ("true","false"):
                raise ValueError(f"invalid assertion value: {ok!r}")
            rows.append((label,ok == "true"))
    return rows

def validate_assertions(spec, checks, exit_code, stderr=""):
    errors = []
    if not checks:
        errors.append("no assertions observed")
    if any(not isinstance(label,str) or type(ok) is not bool for label,ok in checks):
        return ["invalid typed assertion record"]
    failed = [label for label,ok in checks if not ok]
    if spec["kind"] in ("probe-assertions","json-assertions"):
        actual = Counter(label for label,_ in checks)
        expected = Counter(spec["ids"])
        if actual != expected:
            errors.append(f"assertion set mismatch: missing={dict(expected-actual)}, extra={dict(actual-expected)}")
    elif spec["kind"] == "suite-assertions":
        if spec.get("count") is None:
            errors.append("suite exact assertion denominator not frozen")
        elif len(checks) != spec["count"]:
            errors.append(f"suite assertion count mismatch: {len(checks)}")
    else:
        errors.append("external GUI evidence unreviewed")
    allowed = spec.get("allowed_failure")
    if failed:
        legacy = [line.split("TEST_FAIL ",1)[1].strip() for line in stderr.splitlines() if "TEST_FAIL " in line]
        if not (allowed and exit_code == 1 and failed == [allowed] and legacy == [allowed]):
            errors.append(f"assertions failed: {failed}")
    elif exit_code == 1:
        errors.append("exit 1 without exact clean deviation")
    if "SCRIPT ERROR:" in stderr or "Parse Error:" in stderr:
        errors.append("script runtime/parse error")
    return errors

def compare_assertions(before, after):
    return [] if before == after else ["before/after ordered assertion records differ"]

def typed_blocks(path):
    blocks = {}
    current = None
    for line in path.read_bytes().splitlines(keepends=True):
        if line[:1] not in (b" ",b"\t",b"\n",b"\r",b"}",b"]",b")") and b" " in line:
            key, value = line.split(b" ",1)
            if re.fullmatch(rb"[^\s]+", key):
                current = key.decode("utf-8-sig")
                blocks.setdefault(current,[]).append(value)
                continue
        if current is None:
            raise ValueError(f"unlabeled raw record in {path}")
        blocks[current][-1] += line
    return blocks

def compare_raw(paths, keys):
    rows = [typed_blocks(Path(p)) for p in paths]
    errors = []
    for key in keys:
        values = [r.get(key,[]) for r in rows]
        if any(len(v) != 1 for v in values):
            errors.append(f"raw key missing or duplicated: {key}")
        elif any(v != values[0] for v in values[1:]):
            errors.append(f"typed raw mismatch: {key}")
    return errors

def selected_keys(case, diff=None):
    if case == "retry":
        return ["brief","terminal"]
    if case == "deployment":
        return ["confirmed-org","source-fleet-definitions","fixture-actions","viewer-native","viewer-product",
                "next-actual","next-native","camera-selection"]
    if case == "native":
        keys = [f"{diff}/{x}" for x in ("effective","effective-native","display-ally","display-foe","auto-effective")]
        for mode in ("direct","auto"):
            keys += [f"{diff}/{mode}/{x}" for x in ("reinf/natural","reinf/prior","reinf/first")]
            for tick in (0,1,10,100):
                keys += [f"{diff}/{mode}/{kind}/{tick}" for kind in ("actual","native","viewer/actual","viewer/native")]
        return keys
    if case == "poc":
        return ["poc/effective"] + [f"poc/{kind}/{t}" for t in (0,1,10,100) for kind in ("actual","native")]
    if case == "contract":
        return [f"{mode}/{seed}" for mode in ("direct","auto") for seed in (-1,4294967296)] + ["reject/invalid","reject/"]
    if case == "guard-active":
        return ["active/error","active/control-next","active/after-next"]
    if case == "guard-initial":
        return ["initial/return"]
    if case == "invalid-brief":
        return ["legacy-invalid-brief"]
    if case == "alias":
        return [f"{cb}/{s}" for cb in ("density","cross-counter","synthetic") for s in ("effective","initial-events")] + ["synthetic/forced-reinf","invalid-org-fallback"]
    return []
