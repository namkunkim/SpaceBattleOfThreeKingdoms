"""Synthetic Godot-Variant-shaped tests; never launches Godot."""
import struct
from copy import deepcopy

from c_side1_semantics_v8 import bind_capture, bind_wrong_control, inspect_packet, verify_source_stability, verify_fixture_identity

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

def reject(name,fn):
    try: fn()
    except ValueError as err: print("rejected",name,str(err))
    else: raise AssertionError(name)

# IDs are arbitrary positive integers in this synthetic fixture.
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
original=hx(packet(prior))
source=hx(live(prior))
mutated=hx(packet(wrong))
bind_capture(original,source,[])
bind_wrong_control(original,mutated,source,hx(live(wrong)),15)
verify_source_stability(original,source,original,hx(live(prior,9)))
verify_source_stability(original,source,original,hx(dict(reversed(list(live(prior,12).items())))))
print("accepted exact position-only mutation and scoped receipt metadata / envelope field order variation")

with_reverse=[prior[0],{7:contact((400.0,450.0))}]
reject("both packet and state hide same side 1 record in JSON",lambda:bind_capture(hx(packet(with_reverse)),hx(live(with_reverse)),[]))
reject("live side 1 omitted only in JSON",lambda:bind_capture(original,hx(live(with_reverse)),[]))
bad_type=deepcopy(prior)
bad_type[0][15]["err_r"]=30
reject("wrong record type",lambda:bind_capture(hx(packet(bad_type)),hx(live(bad_type)),[]))
bad_id=[{7:contact((400.0,450.0))},{}]
reject("same-side or substituted ID",lambda:bind_capture(hx(packet(bad_id)),hx(live(bad_id)),[]))
bad_wrong=deepcopy(wrong)
bad_wrong[0][15]["conf_bp"]=4000
reject("position plus confidence mutation",lambda:bind_wrong_control(original,hx(packet(bad_wrong)),source,hx(live(bad_wrong)),15))
bad_ctx=packet(wrong)
bad_ctx["context"]["rules"]["sample"]=2
reject("position plus context mutation",lambda:bind_wrong_control(original,hx(bad_ctx),source,hx(live(wrong)),15))
wrong_pos=[{15:contact((1499.0,450.0))},{}]
reject("position mutation not actual live position",lambda:bind_wrong_control(original,hx(packet(wrong_pos)),source,hx(live(wrong_pos)),15))
reject("target did not apply wrong-position control",lambda:bind_wrong_control(original,mutated,source,source,15))
changed_live=live(prior)
changed_live["fleet_positions"][15]=(1501.0,450.0)
reject("source simulation position changed under new receipt metadata",lambda:verify_source_stability(original,source,original,hx(changed_live)))
reordered=deepcopy(prior)
reordered[0][15]=dict(reversed(list(reordered[0][15].items())))
reject("ordered contact record mismatch",lambda:bind_capture(original,hx(live(reordered)),[]))
verify_fixture_identity(original,hx(ctx))
fake_packet=packet(prior)
fake_live=live(prior)
fake_packet["context"]["seed"]=fake_live["seed"]=99
bind_capture(hx(fake_packet),hx(fake_live),[])
reject("joint packet and live fixture substitution",lambda:verify_fixture_identity(hx(fake_packet),hx(ctx)))
print("synthetic only; no actual producer or engine")

