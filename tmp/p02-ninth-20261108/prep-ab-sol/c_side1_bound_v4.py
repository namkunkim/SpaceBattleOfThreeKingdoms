"""Strict conditional C side-1 certificate. No Godot execution."""
import math

from independent_qc_oracle import distance
from legacy_autoresolve_oracle import need
from qc_capture_streams import SERVICE_SEEDS

HORIZONS = {"estimated": 320, "lost": 1920}
LANES = ("before", "after")
INSTANCES = ("native-source", "restore-target")

def fields(value, names, where):
    need(type(value) is dict and value.keys() == set(names), f"{where}: exact fields")

def integer(value, where, expected=None):
    need(type(value) is int, f"{where}: exact int")
    if expected is not None:
        need(value == expected, f"{where}: unexpected value")
    return value

def number(value, where):
    need(type(value) in (int,float) and abs(value)<=1e6 and math.isfinite(value),
         f"{where}: finite bounded number")
    return value

def vector(value, where):
    need(type(value) is list and len(value)==2, f"{where}: two-component vector")
    for index,component in enumerate(value):
        number(component,f"{where}[{index}]")
    return value

def sample_keys():
    return [(lane,instance,seed,case,tick) for lane in LANES for instance in INSTANCES
            for seed in SERVICE_SEEDS for case,last in HORIZONS.items()
            for tick in range(1,last+1,10)]

def case_key(row):
    need(type(row["lane"]) is str and row["lane"] in LANES,"lane")
    need(type(row["instance"]) is str and row["instance"] in INSTANCES,"instance")
    seed=integer(row["seed"],"seed")
    need(seed in SERVICE_SEEDS,"fixture seed")
    need(type(row["case"]) is str and row["case"] in HORIZONS,"fixture case")
    return row["lane"],row["instance"],seed,row["case"]

def fleet(value, side):
    fields(value,("id","side","position","form_offsets","alive"),"fleet")
    integer(value["id"],"fleet ID",side+1)
    integer(value["side"],"fleet side",side)
    need(value["alive"] is True,"fleet alive")
    vector(value["position"],"fleet position")
    offsets=value["form_offsets"]
    need(type(offsets) is list and 1<=len(offsets)<=(10 if side==0 else 4),"fleet offset count")
    for p in offsets:
        vector(p,"formation offset")
    return value

def certify(doc, frozen_fixture_sha256):
    fields(doc,("fixture_sha256","config","initial","evaluations"),"witness document")
    config={"estimated_threshold":15,"distance_units_per_point":25,"period_ticks":10,
            "sensor_shp_02":1,"intellect_bonus":12,"ship_points_div":1}
    fields(doc["config"],config,"source configuration")
    for key,expected in config.items():
        integer(doc["config"][key],key,expected)
    need(type(frozen_fixture_sha256) is str and len(frozen_fixture_sha256)==64
         and all(c in "0123456789abcdef" for c in frozen_fixture_sha256),"frozen source SHA")
    need(type(doc["fixture_sha256"]) is str and doc["fixture_sha256"]==frozen_fixture_sha256,"fixture provenance")
    need(type(doc["initial"]) is list and type(doc["evaluations"]) is list,"witness arrays")
    wanted=sample_keys()
    initial_keys=list(dict.fromkeys(k[:4] for k in wanted))
    observed_initial=[]
    for r in doc["initial"]:
        fields(r,("lane","instance","seed","case","tick","side1_contacts"),"initial receipt")
        observed_initial.append(case_key(r))
        integer(r["tick"],"initial tick",0)
        need(type(r["side1_contacts"]) is list and not r["side1_contacts"],"initial side 1 contacts")
    need(observed_initial==initial_keys,"initial receipts missing, reordered or duplicated")
    observed=[]
    for r in doc["evaluations"]:
        fields(r,("lane","instance","seed","case","tick","evaluating_side","ally","foe","equipment",
                  "intellect","formation","live_shp_02","other_live_ships","view_radius","terrain_sensor_bp",
                  "formation_sensor_bp","chain","skills","ew_lower_bound","conceal_lower_bound"),"evaluation receipt")
        observed.append((*case_key(r),integer(r["tick"],"evaluation tick")))
        integer(r["evaluating_side"],"evaluating side",1)
        ally,foe=fleet(r["ally"],0),fleet(r["foe"],1)
        need(type(r["equipment"]) is str and r["equipment"]=="","no equipment")
        integer(r["intellect"],"intellect",70)
        need(type(r["formation"]) is str and r["formation"]=="FRM-01","formation fixture")
        need(1<=integer(r["live_shp_02"],"live SHP-02")<=4,"live composition")
        integer(r["other_live_ships"],"other live ships",0)
        need(number(r["view_radius"],"view radius")==0,"zero view radius")
        integer(r["terrain_sensor_bp"],"terrain sensor modifier",0)
        integer(r["formation_sensor_bp"],"formation sensor modifier",0)
        need(r["chain"] is False and r["skills"] is False,"no chain or skill effects")
        need(integer(r["ew_lower_bound"],"EW lower bound")>=0,"nonnegative target EW")
        need(integer(r["conceal_lower_bound"],"conceal lower bound")>=0,"nonnegative target conceal")
        d=distance(ally["position"],foe["position"])
        ext=max(distance([0,0],p) for f in (ally,foe) for p in f["form_offsets"])
        need(d>=51 and d>2*ext+1,"insufficient source geometry clearance")
    need(observed==wanted,"evaluation receipts missing, reordered or duplicated")
    return frozenset(initial_keys)

def require_absence(captures,certificate):
    need(type(captures) is list and type(certificate) is frozenset,"certificate and capture types")
    need(certificate==frozenset(k[:4] for k in sample_keys()),"incomplete or absent certificate")
    expected={(lane,instance,seed,case,phase)
              for lane,instance,seed,case in certificate for phase in (case,case+" repaired")}
    seen=set()
    for r in captures:
        fields(r,("lane","instance","seed","case","phase","side","records"),"contact capture")
        key=(*case_key(r),r["phase"])
        need(type(r["phase"]) is str and key in expected and key not in seen,"uncertified or duplicate phase")
        integer(r["side"],"contact capture side",1)
        need(type(r["records"]) is list and not r["records"],"independently excluded opposing record")
        seen.add(key)
    need(seen==expected and bool(expected),"incomplete or absent certificate")


