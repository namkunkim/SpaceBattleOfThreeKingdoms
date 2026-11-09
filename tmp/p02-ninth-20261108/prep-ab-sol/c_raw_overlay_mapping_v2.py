"""Strict whole-lane order and typed identity checks for the C producer overlay."""
from c_raw_overlay_mapping import evidence as read_evidence, phase_ids, restore_pairs as compare_pairs
from c_side1_bound_v4 import HORIZONS,integer
from legacy_autoresolve_oracle import need
from qc_capture_streams import SERVICE_SEEDS

A="native-source"
B="restore-target"

def boundary(phase,tick):
    yield "source-before",A,phase,tick
    yield "restore-request",B,phase,tick
    yield "restore-result",B,phase,tick
    yield "source-after",A,phase,tick

def segment(case):
    final=HORIZONS[case]
    for actor in (A,B):
        yield "initial",actor,"fixture",0
    for actor in (A,B):
        for tick in (1,11):
            yield "eval",actor,"before-relocate",tick
    for actor in (A,B):
        yield "relocate",actor,"fixture",20
    for actor in (A,B):
        for tick in range(21,final+1,10):
            yield "eval",actor,"after-relocate",tick
    phases=phase_ids(case)
    for phase in phases[:2]:
        yield from boundary(phase,final)
    for kind in ("alias-before","alias-after"):
        for actor in (A,B):
            yield kind,actor,case,final
    for phase in phases[2:]:
        yield from boundary(phase,final)
    for actor in (A,B):
        yield "scope-end",actor,"before-suffix",final

def strict_identity(row,lane,seed=None,tick=None):
    integer(row["seed"],"raw seed",seed)
    integer(row["tick"],"raw tick",tick)
    need(row["seed"] in SERVICE_SEEDS and 0<=row["tick"]<=1920,"raw seed or tick range")
    need(integer(row["sim_id"],"raw simulation ID")>0,"simulation ID range")
    need(type(row["actor"]) is str and row["actor"] in (A,B),"raw actor")
    need(type(row["lane"]) is str and row["lane"]==lane and lane in ("before","after"),"raw lane")
    need(type(row["case"]) is str and row["case"] in HORIZONS,"raw case")
    need(type(row["event"]) is str and type(row["phase"]) is str,"raw event/phase type")

def check_stream(rows,receipt):
    expected=[(seed,case,*event) for seed in SERVICE_SEEDS for case in HORIZONS for event in segment(case)]
    need(type(rows) is list and len(rows)==len(expected),"raw lane missing or unexpected events")
    ids={}
    claimed=set()
    prior=-1
    for index,(row,(seed,case,kind,actor,phase,tick)) in enumerate(zip(rows,expected)):
        strict_identity(row,receipt["lane"],seed,tick)
        need((row["case"],row["event"],row["actor"],row["phase"])==(case,kind,actor,phase),"raw causal order")
        integer(row["stream_ordinal"],"raw lane ordinal",index)
        need(all(row[key]==receipt[key] for key in ("run_id","pid","created")),"raw process identity")
        micro=integer(row["mono_usec"],"raw microseconds")
        need(micro>=0 and micro>=prior and integer(row["mono_ns"],"normalized ns")==micro*1000,"raw clock regression or conversion")
        prior=micro
        key=(seed,case,actor)
        sim=row["sim_id"]
        if kind=="initial":
            need(sim not in claimed,"run-scoped simulation ID reused")
            claimed.add(sim)
            ids[key]=sim
        need(ids[key]==sim,"simulation ID mixed between cases or roles")
    return rows

def evidence(path,receipt,approved_producer_sha):
    return check_stream(read_evidence(path,receipt,approved_producer_sha),receipt)

def restore_pairs(rows,seed,case):
    integer(seed,"requested seed")
    need(seed in SERVICE_SEEDS and case in HORIZONS,"requested fixture")
    need(type(rows) is list and bool(rows),"raw rows")
    lane=rows[0]["lane"]
    for row in rows:
        strict_identity(row,lane)
    return compare_pairs(rows,seed,case)
