"""Synthetic-only adversarial tests for the C v4 conditional verifier."""
from copy import deepcopy
from c_side1_bound_v4 import certify, require_absence, sample_keys

SHA="f"*64
def receipt(key):
    lane,instance,seed,case,tick=key
    return dict(lane=lane,instance=instance,seed=seed,case=case,tick=tick)

keys=sample_keys()
initial=[dict(receipt((*key,0)),side1_contacts=[]) for key in dict.fromkeys(k[:4] for k in keys)]
doc=dict(fixture_sha256=SHA, config=dict(estimated_threshold=15,distance_units_per_point=25,
         period_ticks=10,sensor_shp_02=1,intellect_bonus=12,ship_points_div=1),initial=initial,evaluations=[
    dict(receipt(key),evaluating_side=1,ally=dict(id=1,side=0,position=[400,450],form_offsets=[[0,0]],alive=True),
         foe=dict(id=2,side=1,position=[500,450],form_offsets=[[0,0]],alive=True),
         equipment="",intellect=70,formation="FRM-01",live_shp_02=4,other_live_ships=0,
         view_radius=0,terrain_sensor_bp=0,formation_sensor_bp=0,chain=False,skills=False,
         ew_lower_bound=0,conceal_lower_bound=0) for key in keys])
certificate=certify(doc,SHA)
captures=[dict(lane=r["lane"],instance=r["instance"],seed=r["seed"],case=r["case"],
               phase=phase,side=1,records=[]) for r in initial for phase in (r["case"],r["case"]+" repaired")]
require_absence(captures,certificate)
print(f"accepted synthetic: {len(keys)} evals, {len(initial)} initial receipts, {len(captures)} captures")

def reject(name,callback):
    try: callback()
    except ValueError as err: print("rejected",name,str(err))
    else: raise AssertionError(name)

r=doc["evaluations"][0]
for name, mapping, field, bad in [
    ("boolean fleet ID",r["ally"],"id",True),
    ("float tick",r,"tick",1.0),
    ("boolean seed",r,"seed",False),
    ("boolean evaluating side",r,"evaluating_side",True),
    ("boolean fleet side",r["ally"],"side",False),
    ("boolean live ship count",r,"live_shp_02",True),
    ("float ship count",r,"live_shp_02",4.0),
    ("float intellect",r,"intellect",70.0),
    ("boolean radius",r,"view_radius",False),
    ("nonfinite position",r["ally"],"position",[float("nan"),450]),
    ("nonfinite offset",r["foe"],"form_offsets",[[float("inf"),0]]),
    ("boolean coordinate",r["ally"],"position",[True,450]),
    ("empty offsets",r["ally"],"form_offsets",[]),
    ("oversized offsets",r["foe"],"form_offsets",[[0,0]]*5),
    ("missing evaluation",doc,"evaluations",doc["evaluations"][1:]),
    ("duplicate evaluation",doc,"evaluations",doc["evaluations"]+[r]),
    ("missing initial",doc,"initial",initial[1:]),
    ("prior contact",initial[0],"side1_contacts",[1]),
    ("negative EW",r,"ew_lower_bound",-1),
    ("negative conceal",r,"conceal_lower_bound",-1),
    ("fixture SHA drift",doc,"fixture_sha256","a"*64),
    ("config drift",doc["config"],"estimated_threshold",14),
    ("lane identity drift",r,"lane","after"),
    ("instance identity drift",r,"instance","restore-target"),
    ("uncertified geometry",r["foe"],"position",[445,450]),
]:
    original=mapping[field]
    mapping[field]=bad
    reject(name,lambda:certify(doc,SHA))
    mapping[field]=original
original=r.pop("skills")
reject("omitted required field",lambda:certify(doc,SHA))
r["skills"]=original
reject("capture missing",lambda:require_absence(captures[1:],certificate))
reject("empty captures cannot substitute for a certificate",lambda:require_absence(captures,frozenset()))
mut=deepcopy(captures)
mut[0]["records"]=[1]
reject("unexpected opposing contact",lambda:require_absence(mut,certificate))
reject("subset certificate",lambda:require_absence(captures,frozenset([next(iter(certificate))])))
mut[0]["records"]=[]
mut[0]["side"]=True
reject("boolean capture side",lambda:require_absence(mut,certificate))
