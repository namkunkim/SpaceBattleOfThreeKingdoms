"""Synthetic raw type and complete order mutations; no child process."""
from c_raw_overlay_mapping_v2 import check_stream,segment,restore_pairs
from c_side1_bound_v4 import HORIZONS
from qc_capture_streams import SERVICE_SEEDS

receipt=dict(lane="before",run_id="synthetic",pid=1,created=1)
rows=[]
for index,(seed,case) in enumerate((s,c) for s in SERVICE_SEEDS for c in HORIZONS):
    for event,actor,phase,tick in segment(case):
        rows.append(dict(receipt,seed=seed,case=case,event=event,actor=actor,phase=phase,tick=tick,
            sim_id=2*index+1+(actor=="restore-target"),stream_ordinal=len(rows),mono_usec=12,mono_ns=12000))
assert len(check_stream(rows,receipt))==5080
print("accepted 5080 synthetic whole-lane rows with simultaneous timestamp values")
def reject(name,fn):
    try:fn()
    except ValueError as e:print("rejected",name,str(e))
    else:raise AssertionError(name)

def mutate(index,**kw):
    return [*rows[:index],dict(rows[index],**kw),*rows[index+1:]]
reject("boolean seed",lambda:check_stream(mutate(0,seed=False),receipt))
reject("boolean tick",lambda:check_stream(mutate(2,tick=True),receipt))
reject("boolean sim ID",lambda:check_stream(mutate(0,sim_id=True),receipt))
reject("float sim ID",lambda:check_stream(mutate(0,sim_id=1.0),receipt))
reject("negative tick",lambda:check_stream(mutate(2,tick=-1),receipt))
reject("instance ID reuse",lambda:check_stream(mutate(1,sim_id=1),receipt))
reject("role swap",lambda:check_stream(mutate(0,actor="restore-target"),receipt))
reject("lane mix",lambda:check_stream(mutate(0,lane="after"),receipt))
reject("phase mix",lambda:check_stream(mutate(2,phase="after-relocate"),receipt))
reject("unexpected event",lambda:check_stream(mutate(2,event="extra"),receipt))
reject("missing eval",lambda:check_stream(rows[:2]+rows[3:],receipt))
reject("raw reorder",lambda:check_stream([rows[1],rows[0],*rows[2:]],receipt))
reject("clock regression",lambda:check_stream(mutate(2,mono_usec=11,mono_ns=11000),receipt))
reject("bad clock conversion",lambda:check_stream(mutate(2,mono_ns=12001),receipt))
reject("restore pairs rejects bool seed before filtering",lambda:restore_pairs(mutate(0,seed=False),0,"estimated"))
print("synthetic only")
