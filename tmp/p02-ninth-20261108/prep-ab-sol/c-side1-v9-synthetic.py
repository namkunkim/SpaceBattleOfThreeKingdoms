"""Synthetic mandatory identity/atomicity mutations, no engine launch."""
import hashlib
import json
import struct
from copy import deepcopy
from pathlib import Path
from tempfile import TemporaryDirectory

from c_side1_pipeline_v9 import check_case

def pack(fmt,*vals):
    return struct.pack("<"+fmt,*vals)

def enc(value):
    typ=type(value)
    if typ is bool: return pack("II",1,int(value))
    if typ is int: return pack("Ii",2,value)
    if typ is float: return pack("If",3,value)
    if typ is str:
        data=value.encode()
        return pack("II",4,len(data))+data+bytes((-len(data))%4)
    if typ is tuple: return pack("Iff",5,*value)
    if typ is dict:
        return pack("II",27,len(value))+b"".join(enc(k)+enc(v) for k,v in value.items())
    if typ is list: return pack("II",28,len(value))+b"".join(map(enc,value))
    raise TypeError(typ)

def hx(value):
    return enc(value).hex()

roster=[dict(id=7,side=0,faction="a"),dict(id=15,side=1,faction="b")]
ctx=dict(profile_id="synthetic",seed=23,hz=10,tick=320,clock_ms=32000,roster=roster,
         rules={"sample":1},scenario={},combat={},detection_derived={"period":10},supply_derived={})
def contact(pos):
    return dict(seen=11,pos=pos,state="estimated",conf_bp=5000,err_r=30.0)
def packet(books):
    return dict(format="i01b/service-slice/1",context=deepcopy(ctx),
                detection=dict(active=True,contacts=deepcopy(books)),supply=dict(active=False,fleets=[]))
def live(books,ordinal=3):
    return dict(**{k:ctx[k] for k in ("profile_id","seed","hz","tick","clock_ms","roster")},
                contacts=deepcopy(books),fleet_positions={7:(400.0,450.0),15:(1500.0,450.0)},
                receipt_metadata=dict(ordinal=ordinal,mono_ns=100+ordinal))
prior=[{15:contact((500.0,450.0))},{}]
wrong=[{15:contact((1500.0,450.0))},{}]
cleared=[{},{}]
def phase(books,before,ordinal):
    return dict(packet_hex=hx(packet(books)),target_before=hx(live(before,ordinal)),
                target_after=hx(live(books,ordinal+1)),result={"ok":True},records=[])
base=dict(reported_contact_id=15,source_first=hx(live(prior,1)),source_repaired=hx(live(prior,10)),
          phases={"first":phase(prior,cleared,2),"wrong-position-control":phase(wrong,prior,5),"repaired":phase(prior,wrong,8)})

def hash_bytes(raw):
    return hashlib.sha256(raw).hexdigest()

def reject(name,callback):
    try:callback()
    except (ValueError,FileNotFoundError) as err:print("rejected",name,str(err))
    else:raise AssertionError(name)

with TemporaryDirectory(dir=Path(__file__).resolve().parent) as folder:
    path=Path(folder)/"pin.json"
    good=json.dumps(dict(seed=23,case="estimated",context_hex=hx(ctx))).encode()
    path.write_bytes(good)
    approved=hash_bytes(good)
    def validate(sample=base,pin=path,approval=approved):
        check_case(sample,pin,approval,seed=23,case="estimated")
    validate()
    print("accepted exact fixture, three phase-local external states, varying receipt metadata")
    reject("mandatory fixture file missing",lambda:validate(pin=path.with_name("missing.json")))
    reject("mandatory independent approval missing",lambda:validate(approval=None))
    counterfeit=json.dumps(dict(seed=23,case="estimated",context_hex=hx(dict(ctx,clock_ms=32100)))).encode()
    path.write_bytes(counterfeit)
    reject("self-consistent candidate pin bytes replaced",validate)
    path.write_bytes(good)
    bad=deepcopy(base)
    bad["reported_contact_id"]=7
    reject("forged selected contact ID",lambda:validate(bad))
    bad=deepcopy(base)
    fake=packet(prior)
    fake["context"]["clock_ms"]=32100
    fake_live=live(prior)
    fake_live["clock_ms"]=32100
    bad["phases"]["first"]["packet_hex"]=hx(fake)
    bad["source_first"]=bad["phases"]["first"]["target_after"]=hx(fake_live)
    reject("joint candidate fixture swap",lambda:validate(bad))
    bad=deepcopy(base)
    moved=live(wrong)
    moved["fleet_positions"][15]=(1498.0,450.0)
    bad["phases"]["wrong-position-control"]["target_after"]=hx(moved)
    reject("wrong phase target external position altered",lambda:validate(bad))
    bad=deepcopy(base)
    moved_before=live(prior)
    moved_before["fleet_positions"][15]=(1498.0,450.0)
    bad["phases"]["wrong-position-control"]["target_before"]=hx(moved_before)
    bad["phases"]["wrong-position-control"]["target_after"]=hx(moved)
    reject("external position altered consistently before and after",lambda:validate(bad))
    bad=deepcopy(base)
    bad["phases"]["repaired"]["target_before"]=hx(live(prior))
    reject("target selected state drift between phases",lambda:validate(bad))
    bad=deepcopy(base)
    bad["phases"]["wrong-position-control"]["result"]["ok"]=1
    reject("mistyped restore success",lambda:validate(bad))
    bad=deepcopy(base)
    del bad["phases"]["wrong-position-control"]
    reject("mandatory wrong-position phase missing",lambda:validate(bad))
print("synthetic only; no actual producer or engine")
