"""Full synthetic raw-to-v9 C rehearsal, no process or engine launch."""
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import struct
from tempfile import TemporaryDirectory

from c_offline_rehearsal import verify
from c_raw_overlay_mapping_v2 import segment,A,B
from c_side1_bound_v4 import HORIZONS,LANES
from qc_capture_streams import SERVICE_SEEDS

CASES=[(seed,case) for seed in SERVICE_SEEDS for case in HORIZONS]

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def enc(v):
    p=lambda fmt,*args:struct.pack("<"+fmt,*args)
    if type(v) is bool:return p("II",1,int(v))
    if type(v) is int:return p("Ii",2,v) if -2**31<=v<2**31 else p("Iq",2|1<<16,v)
    if type(v) is float:return p("If",3,v)
    if type(v) is str:
        b=v.encode()
        return p("II",4,len(b))+b+bytes((-len(b))%4)
    if type(v) is tuple:return p("Iff",5,*v)
    if type(v) is list:return p("II",28,len(v))+b"".join(map(enc,v))
    if type(v) is dict:return p("II",27,len(v))+b"".join(enc(k)+enc(x) for k,x in v.items())
    raise TypeError(type(v))

def write_json(path,value):
    data=(json.dumps(value,separators=(",",":"))+"\n").encode()
    path.write_bytes(data)
    return sha(data)

def make_context(seed,case):
    tick=HORIZONS[case]
    return dict(profile_id="synthetic",seed=seed,hz=10,tick=tick,clock_ms=tick*100,
                roster=[dict(id=1,side=0,faction="a"),dict(id=2,side=1,faction="b")],
                rules={},scenario={},combat={},detection_derived={},supply_derived={})

def geometry(tick,position):
    def fleet(id,pos,ship,number):
        return dict(id=id,side=id-1,position=pos,form_offsets=[(0.,0.)],dead=False,
                    max_hull=100,equipment="",stats=dict(intellect=70),formation="FRM-01",
                    composition={ship:number},stages={ship:[number,0,0,0,0]})
    return dict(authoritative_tick=tick,evaluating_side=1,
        fleets=[fleet(1,(400.,450.),"SHP-01",10),fleet(2,position,"SHP-02",4)],
        detection_config=dict(estimated=15,distance_units_per_point=25,ship_points_div=1,eval_period_s=1,
          view_r=0,radar_r=0,ship_sensor={"SHP-02":1},intellect_bands=[{"min":70,"max":79,"sensor_points":12}],
          ship_ew={"SHP-01":0},equip_ew={}),
        terrain_zones=[],formation_config={"FRM-01":{"detection_bp":0}},has_chain=False,has_skills=False)

def rows(lane,mutation):
    ordinal=0
    changed=False
    for number,(seed,case) in enumerate(CASES):
        context=make_context(seed,case)
        def contacts(pos):
            return [{2:dict(seen=11,pos=pos,state=case,conf_bp=5000,err_r=30.0)},{}]
        source_books=contacts((500.,450.))
        wrong_books=contacts((1500.,450.))
        target_books=[{},{}]
        for kind,actor,phase,tick in segment(case):
            sim=2*number+(1 if actor==A else 2)
            request=f"{2*number+2}/{phase}"
            if kind=="eval":
                pos=(500.,450.) if phase=="before-relocate" else (1500.,450.)
                if not changed and mutation=="geometry" and lane=="after":
                    pos=(430.,450.)
                    changed=True
                data=geometry(tick,pos)
            elif kind=="initial":
                data={"contacts":[{},{}]}
            elif kind in ("source-before","source-after","restore-request","restore-result"):
                expected=wrong_books if phase=="wrong-position-control" else source_books
                if kind=="restore-result":
                    target_books=expected
                books=source_books if actor==A else target_books
                live={k:context[k] for k in ("profile_id","seed","hz","tick","clock_ms","roster")}
                live.update(contacts=books,fleet_positions={1:(400.,450.),2:(1500.,450.)},
                    receipt_metadata=dict(ordinal=ordinal,mono_ns=(ordinal+1)*1000))
                data=dict(request_id=request,live_raw=enc(live).hex(),state={"outside":{"clock":tick},"selected":{"contacts":books}})
                if actor==B:
                    packet=dict(format="i01b/service-slice/1",context=context,detection={"active":True,"contacts":expected},
                                supply={"active":False,"fleets":[]})
                    packet_bytes=enc(packet)
                    data.update(packet=packet,packet_raw=packet_bytes.hex(),packet_raw_sha256=sha(packet_bytes))
                if kind=="restore-result":
                    data["result"]={"ok":True}
                    if not changed and mutation=="request" and lane=="after":
                        data["request_id"]="unrelated request"
                        changed=True
            else:
                data={}
            yield dict(stream_ordinal=ordinal,mono_usec=ordinal+1,sim_id=sim,actor=actor,case=case,
                       seed=seed,tick=tick,event=kind,phase=phase,payload_hex=enc(data).hex())
            ordinal+=1

with TemporaryDirectory(dir=Path(__file__).resolve().parent) as temp:
    root=Path(temp)
    fixture=root/"independent-source.txt"
    fixture.write_bytes(b"synthetic fixture source")
    entries={fixture.name:sha(fixture.read_bytes())}
    digest=sha(json.dumps(entries,sort_keys=True,separators=(",",":")).encode())
    fixture_pin=root/"fixture.json"
    fixture_sha=write_json(fixture_pin,dict(fixture_sources=entries,fixture_provenance_digest=digest))
    pins=[]
    for seed,case in CASES:
        path=root/f"context-{seed}-{case}.json"
        pin=write_json(path,dict(seed=seed,case=case,context_hex=enc(make_context(seed,case)).hex()))
        pins.append(dict(seed=seed,case=case,path=str(path),approved_sha256=pin))
    approval_path=root/"approval.json"
    def build(mutation=None):
        lanes={}
        for lane in LANES:
            path=root/f"{lane}.log"
            data=b"".join(b"K6_C_PRODUCER "+json.dumps(r,separators=(",",":")).encode()+b"\n" for r in rows(lane,mutation))
            path.write_bytes(data)
            receipt=root/f"{lane}.json"
            run=f"synthetic-{lane}" if mutation!="cross-run" else "synthetic-reused"
            receipt_sha=write_json(receipt,dict(lane=lane,run_id=run,pid=10+LANES.index(lane),created=100,
                                                producer_sha="a"*64,raw_sha=sha(data)))
            lanes[lane]=dict(raw=str(path),receipt=str(receipt),receipt_sha=receipt_sha)
        return write_json(approval_path,dict(producer_sha="a"*64,fixture_root=str(root),fixture_manifest=str(fixture_pin),
            fixture_manifest_sha=fixture_sha,lanes=lanes,case_pins=pins))
    exact=build()
    result=verify(approval_path,exact)
    assert result=={"lane_rows":10160,"evaluation_witnesses":8960,"restore_calls":200}
    print("accepted full synthetic two-lane rehearsal",result)
    def reject(name,callback):
        try: callback()
        except ValueError as err: print("rejected",name,str(err))
        else: raise AssertionError(name)
    reject("wrong external approval SHA",lambda:verify(approval_path,"0"*64))
    pin=Path(pins[0]["path"])
    original=pin.read_bytes()
    pin.write_bytes(original+b" ")
    reject("fixture case pin changed",lambda:verify(approval_path,exact))
    pin.write_bytes(original)
    for mutation in ("geometry","request","cross-run"):
        candidate=build(mutation)
        reject(mutation,lambda:verify(approval_path,candidate))
print("synthetic only")
