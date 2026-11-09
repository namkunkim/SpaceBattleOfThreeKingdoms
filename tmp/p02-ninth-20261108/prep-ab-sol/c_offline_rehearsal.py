"""Offline two-lane C join: ordered raw receipts, geometry and mandatory v9 pins."""
import hashlib
import json
from pathlib import Path

from c_raw_overlay_mapping_v2 import evidence
from c_raw_v4_semantic_adapter import collect_case
from c_side1_bound_v4 import HORIZONS,LANES,INSTANCES,certify,fields
from c_side1_chain_v6 import pinned_inputs
from c_side1_pipeline_v9 import check_case
from c_side1_semantics_v8 import decode,mapping,typed
from legacy_autoresolve_oracle import need,unique
from qc_capture_streams import SERVICE_SEEDS

def read_pinned(path,digest):
    raw=Path(path).read_bytes()
    need(hashlib.sha256(raw).hexdigest()==digest,"external evidence pin SHA")
    return json.loads(raw,object_pairs_hook=unique)

def numeric(value):
    need(value[0] in (2,3),"typed numeric fixture setting")
    return value[2]

def config_int(config,key,want):
    need(numeric(config[key])==want,f"fixture setting {key}")
    return want

def shape(raw,side):
    v=mapping(raw)
    ident=typed(v["id"],2,"fleet id")
    need(ident==side+1 and typed(v["side"],2,"fleet side")==side,"evaluation fleet identity")
    need(typed(v["max_hull"],2,"fleet max hull")>0,"fleet max hull")
    return v,dict(id=ident,side=side,alive=not typed(v["dead"],1,"fleet dead"),
        position=list(typed(v["position"],5,"fleet position")),
        form_offsets=[list(typed(item,5,"formation offset")) for item in typed(v["form_offsets"],28,"formation offsets")])

def live_stages(fleet):
    comp=mapping(fleet["composition"])
    stages=mapping(fleet["stages"])
    need(comp.keys()==stages.keys(),"ship classes and stage keys differ")
    counts={}
    for ship,encoded in stages.items():
        values=[typed(x,2,"stage count") for x in typed(encoded,28,"ship stage array")]
        need(len(values)==5 and min(values)>=0 and sum(values)<=typed(comp[ship],2,"composition count"),
             "ship stage bounds")
        counts[ship]=sum(values[:3])
    return counts

def make_geometry(row,payload):
    need(typed(payload["authoritative_tick"],2,"pre-eval tick")==row["tick"],"pre-eval tick mismatch")
    side=typed(payload["evaluating_side"],2,"evaluating side")
    need(side==1,"pre-eval side")
    fleets=typed(payload["fleets"],28,"evaluation fleets")
    need(len(fleets)==2,"two-fleet geometry fixture")
    af,ally=shape(fleets[0],0)
    bf,foe=shape(fleets[1],1)
    config=mapping(payload["detection_config"])
    config_int(config,"estimated",15)
    config_int(config,"distance_units_per_point",25)
    config_int(config,"ship_points_div",1)
    config_int(config,"eval_period_s",1)
    config_int(config,"view_r",0)
    config_int(config,"radar_r",0)
    need(numeric(mapping(config["ship_sensor"])["SHP-02"])==1,"SHP-02 sensor")
    intellect=typed(mapping(bf["stats"])["intellect"],2,"foe intellect")
    bands=[mapping(x) for x in typed(config["intellect_bands"],28,"intellect bands")]
    matching=[b for b in bands if numeric(b["min"])<=intellect<=numeric(b["max"])]
    need(len(matching)==1 and numeric(matching[0]["sensor_points"])==12,"intellect sensor bonus")
    form=typed(bf["formation"],4,"foe formation")
    form_config=mapping(mapping(payload["formation_config"])[form])
    bonus=config_int(form_config,"detection_bp",0)
    need(not typed(payload["terrain_zones"],28,"terrain zones"),"nonempty terrain requires different oracle")
    counts=live_stages(bf)
    enemy_ew=mapping(config["ship_ew"])
    need(all(numeric(enemy_ew[ship])>=0 for ship in live_stages(af)),"negative target ship EW")
    gear=typed(af["equipment"],4,"ally equipment")
    need(not gear or numeric(mapping(config["equip_ew"])[gear])>=0,"negative target equipment EW")
    return dict(evaluating_side=side,ally=ally,foe=foe,
        equipment=typed(bf["equipment"],4,"foe equipment"),intellect=intellect,formation=form,
        live_shp_02=counts.get("SHP-02",0),other_live_ships=sum(n for s,n in counts.items() if s!="SHP-02"),
        view_radius=0,terrain_sensor_bp=0,formation_sensor_bp=bonus,
        chain=typed(payload["has_chain"],1,"chain active"),skills=typed(payload["has_skills"],1,"skills active"),
        ew_lower_bound=0,conceal_lower_bound=0)

def origin(row):
    return dict(lane=row["lane"],instance=row["actor"],seed=row["seed"],case=row["case"],tick=row["tick"])

def verify(approval_path,approval_sha):
    approved=read_pinned(approval_path,approval_sha)
    fields(approved,("producer_sha","fixture_root","fixture_manifest","fixture_manifest_sha","lanes","case_pins"),"independent approval")
    fixture=pinned_inputs(approved["fixture_root"],approved["fixture_manifest"],approved["fixture_manifest_sha"])
    cases=[(seed,case) for seed in SERVICE_SEEDS for case in HORIZONS]
    pins=approved["case_pins"]
    need([(x["seed"],x["case"]) for x in pins]==cases,"20 independently approved ordered case pins")
    need(tuple(approved["lanes"])==LANES,"approved lane order")
    witness=dict(fixture_sha256=fixture,config=dict(estimated_threshold=15,distance_units_per_point=25,period_ticks=10,
        sensor_shp_02=1,intellect_bonus=12,ship_points_div=1),initial=[],evaluations=[])
    run_ids=set()
    rows_by_lane={}
    for lane,entry in approved["lanes"].items():
        fields(entry,("raw","receipt","receipt_sha"),"approved lane entry")
        receipt=read_pinned(entry["receipt"],entry["receipt_sha"])
        need(receipt["lane"]==lane and receipt["run_id"] not in run_ids,"independent distinct lane runs")
        run_ids.add(receipt["run_id"])
        rows=evidence(entry["raw"],receipt,approved["producer_sha"])
        rows_by_lane[lane]=rows
        for row in rows:
            if row["event"]=="eval":
                witness["evaluations"].append(origin(row)|make_geometry(row,mapping(decode(row["payload_hex"]))))
            elif row["event"]=="initial":
                books=typed(mapping(decode(row["payload_hex"]))["contacts"],28,"initial contact array")
                need(len(books)==2 and not typed(books[1],27,"initial side 1 book"),"initial side 1 not empty")
                witness["initial"].append(origin(row)|{"side1_contacts":[]})
    def witness_order(r):
        return LANES.index(r["lane"]),INSTANCES.index(r["instance"]),r["seed"],tuple(HORIZONS).index(r["case"]),r["tick"]
    witness["initial"].sort(key=witness_order)
    witness["evaluations"].sort(key=witness_order)
    certify(witness,fixture)
    for rows in rows_by_lane.values():
        for pin,(seed,case) in zip(pins,cases):
            capture=collect_case(rows,seed,case)
            source=mapping(decode(capture["source_first"]))
            roster=typed(source["roster"],28,"source roster")
            need(len(roster)>=2,"source contact slot")
            capture["reported_contact_id"]=typed(mapping(roster[1])["id"],2,"actual selected ID")
            check_case(capture,pin["path"],pin["approved_sha256"],seed=seed,case=case)
    return {"lane_rows":sum(map(len,rows_by_lane.values())),
            "evaluation_witnesses":len(witness["evaluations"]),"restore_calls":len(cases)*5*len(rows_by_lane)}
