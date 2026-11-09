"""Conditional, independent side-1 no-contact certificate for the P2B two-fleet fixture."""
from independent_qc_oracle import distance
from legacy_autoresolve_oracle import need
from qc_capture_streams import SERVICE_SEEDS

HORIZONS={"estimated":320,"lost":1920}

def keys():
    return [(seed,case,tick) for seed in SERVICE_SEEDS for case,last in HORIZONS.items() for tick in range(1,last+1,10)]

def certify(rows):
    need([(r["seed"],r["case"],r["tick"]) for r in rows]==keys(),"C side 1 complete ordered evaluation witnesses")
    for r in rows:
        need(r["ally"]["id"]==1 and r["foe"]["id"]==2,"C source fleet IDs")
        need(r["ally"]["side"]==0 and r["foe"]["side"]==1,"C source fleet sides")
        foe=r["foe"]
        need(foe["equipment"]=="" and foe["intellect"]==70 and foe["formation"]=="FRM-01","C source sensor fixture")
        need(foe["live_shp_02"] in range(5) and foe["other_live_ships"]==0,"C source fleet composition")
        need(r["view_radius"]==0 and r["terrain_sensor_bp"]==0 and r["formation_sensor_bp"]==0
             and r["has_chain"] is False and r["has_skill"] is False,"C source zero-view/base sensor fixture")
        d=distance(r["ally"]["position"],foe["position"])
        ext=max(distance([0,0],p) for ship in (r["ally"],foe) for p in ship["form_offsets"])
        # Margin keeps the certificate away from single-precision threshold boundaries.
        need(d>=51 and d>2*ext+1,"C insufficient source geometry bound")
        # Maximum score 4 SHP-02 + intellect 12 - distance penalty 2 = 14 < 15.
        # EW is nonnegative and may reduce it further.
    return {(seed,case):[] for seed in SERVICE_SEEDS for case in HORIZONS}

def require_absence(rows,certificate):
    for r in rows:
        if r["side"]==1:
            key=(r["seed"],r["phase"].split()[0])
            need(key in certificate,"C source certificate missing")
            need([record["id"] for record in r["records"]]==certificate[key],"C independently excluded opposing record")
