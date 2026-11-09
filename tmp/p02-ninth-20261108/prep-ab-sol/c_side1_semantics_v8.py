"""Decode and compare the service-slice packet and a scoped live observation."""
import math
import re
import struct

from legacy_autoresolve_oracle import need

def decode(text):
    need(type(text) is str and 8<=len(text)<=2_000_000 and len(text)%2==0
         and re.fullmatch(r"[0-9a-f]+",text) is not None,"Variant hex")
    raw=bytes.fromhex(text)
    offset=0
    def take(size):
        nonlocal offset
        need(0<=size<=len(raw)-offset,"truncated Variant")
        data=raw[offset:offset+size]
        offset+=size
        return data
    def read(fmt):
        return struct.unpack("<"+fmt,take(struct.calcsize("<"+fmt)))
    def text_value():
        length,=read("I")
        value=take(length).decode("utf8")
        need(not any(take((-length)%4)),"Variant padding")
        return value
    def visit(depth):
        need(depth<=32,"Variant depth")
        header,=read("I")
        tag,flags=header&255,header>>16
        need(header&0xff00==0,"Variant reserved header bits")
        metadata=()
        if tag==0 and flags==0:
            data=None
        elif tag==1 and flags==0:
            bit,=read("I")
            need(bit in (0,1),"Variant boolean")
            data=bool(bit)
        elif tag==2 and flags in (0,1):
            data=read("q" if flags else "i")[0]
        elif tag in (3,5) and flags in (0,1):
            values=read(("d" if flags else "f")*(2 if tag==5 else 1))
            need(all(math.isfinite(v) for v in values),"Variant nonfinite")
            data=values if tag==5 else values[0]
        elif tag in (4,21) and flags==0:
            data=text_value()
        elif tag in (27,28):
            n=2 if tag==27 else 1
            kinds=tuple((flags>>(2*i))&3 for i in range(n))
            need(flags>>(2*n)==0 and all(k in (0,1) for k in kinds),"unsupported container metadata")
            metadata=tuple(read("I")[0] if k else None for k in kinds)
            need(all(t is None or t in (1,2,3,4,5,21,27,28) for t in metadata),"unsupported typed container")
            count,=read("I")
            need(count<=4096,"Variant container count")
            if tag==28:
                data=tuple(visit(depth+1) for _ in range(count))
                need(metadata[0] is None or all(v[0]==metadata[0] for v in data),"array element type")
            else:
                entries=[]
                keys=set()
                for _ in range(count):
                    key,value=visit(depth+1),visit(depth+1)
                    need(key[0] in (2,4,21) and key not in keys,"duplicate or unsupported dictionary key")
                    need(all(t is None or actual[0]==t for t,actual in zip(metadata,(key,value))),"dictionary entry type")
                    keys.add(key)
                    entries.append((key,value))
                data=tuple(entries)
        else:
            raise ValueError(f"unsupported Variant tag/flags {tag}/{flags}")
        return tag,metadata,data
    result=visit(0)
    need(offset==len(raw),"trailing Variant bytes")
    return result

def mapping(value,keys=None):
    need(value[0]==27,"expected Variant dictionary")
    data={}
    for key,v in value[2]:
        need(key[0]==4 and key[2] not in data,"expected exact string key")
        data[key[2]]=v
    if keys is not None:
        need(data.keys()==set(keys),"Variant dictionary fields")
    return data

def value_at(value,key,tag=4):
    need(value[0]==27,"Variant path must be dictionary")
    for k,v in value[2]:
        if k==(tag,(),key):
            return v
    raise ValueError(f"missing Variant path {key}")

def replace_at(value,path,replacement):
    if not path:
        return replacement
    key,*rest=path
    if value[0]==28:
        need(type(key) is int and 0<=key<len(value[2]),"Variant array path")
        children=list(value[2])
        children[key]=replace_at(children[key],rest,replacement)
        return value[0],value[1],tuple(children)
    need(value[0]==27,"Variant path parent")
    tag=2 if type(key) is int else 4
    selected=value_at(value,key,tag)
    return value[0],value[1],tuple(
        (k,replace_at(selected,rest,replacement) if k==(tag,(),key) else v)
        for k,v in value[2])

def typed(value,tag,label):
    need(value[0]==tag,f"{label}: Variant type")
    return value[2]

CONTEXT_KEYS=("profile_id","seed","hz","tick","clock_ms","roster","rules","scenario","combat","detection_derived","supply_derived")
RECORD_KEYS=("seen","pos","state","conf_bp","err_r")
LIVE_KEYS=("profile_id","seed","hz","tick","clock_ms","roster","contacts","fleet_positions","receipt_metadata")

def roster_ids(raw):
    roster={}
    for value in typed(raw,28,"roster"):
        row=mapping(value,("id","side","faction"))
        ident=typed(row["id"],2,"fleet ID")
        side=typed(row["side"],2,"fleet side")
        typed(row["faction"],4,"fleet faction")
        need(ident>0 and ident not in roster and side in (0,1),"roster identity")
        roster[ident]=side
    return roster

def contact_books(raw,roster,tick):
    books=typed(raw,28,"contact books")
    need(len(books)==2,"two contact sides")
    for side,book in enumerate(books):
        for key,record in typed(book,27,"contact book"):
            ident=typed(key,2,"contact fleet ID")
            need(roster.get(ident)==1-side,"contact ID must be opposing fleet")
            rec=mapping(record,RECORD_KEYS)
            need(0<=typed(rec["seen"],2,"contact seen")<=tick,"contact seen range")
            typed(rec["pos"],5,"contact position")
            need(typed(rec["state"],4,"contact state") in ("confirmed","estimated","lost"),"contact state value")
            need(0<=typed(rec["conf_bp"],2,"contact confidence")<=10000,"contact confidence range")
            need(typed(rec["err_r"],3,"contact error radius")>=0,"contact radius")
    return books

def inspect_packet(raw):
    node=decode(raw)
    packet=mapping(node,("format","context","detection","supply"))
    need(typed(packet["format"],4,"format")=="i01b/service-slice/1","packet format")
    context=mapping(packet["context"],CONTEXT_KEYS)
    tick=typed(context["tick"],2,"context tick")
    roster=roster_ids(context["roster"])
    detect=mapping(packet["detection"],("active","contacts"))
    supply=mapping(packet["supply"],("active","fleets"))
    need(typed(detect["active"],1,"detection active") and not typed(supply["active"],1,"supply active")
         and not typed(supply["fleets"],28,"supply fleets"),"detection-only fixture")
    books=contact_books(detect["contacts"],roster,tick)
    return node,context,books

def inspect_live(raw,context,records):
    live=mapping(decode(raw),LIVE_KEYS)
    for field in ("profile_id","seed","hz","tick","clock_ms","roster"):
        need(live[field]==context[field],f"live fixture identity: {field}")
    roster=roster_ids(live["roster"])
    books=contact_books(live["contacts"],roster,typed(live["tick"],2,"live tick"))
    need(type(records) is list and not records and not books[1][2],"decoded side 1 contradicts reported absence")
    positions={}
    for key,pos in typed(live["fleet_positions"],27,"live positions"):
        ident=typed(key,2,"position ID")
        need(ident in roster,"unknown live position ID")
        typed(pos,5,"live position")
        positions[ident]=pos
    need(positions.keys()==roster.keys(),"missing live positions")
    # Only this separate receipt field is outside the immutable simulation projection.
    metadata=mapping(live.pop("receipt_metadata"),("ordinal","mono_ns"))
    need(typed(metadata["ordinal"],2,"receipt ordinal")>=0 and typed(metadata["mono_ns"],2,"receipt time")>0,"receipt metadata range")
    return live,books,positions

def bind_capture(packet_hex,live_hex,records):
    _,context,books=inspect_packet(packet_hex)
    live,live_books,positions=inspect_live(live_hex,context,records)
    need(not books[1][2],"packet decoded side 1 contradicts reported absence")
    need(live_books==books,"live and packet ordered typed contacts differ")
    return live,positions

def verify_wrong_position(original_hex,mutated_hex,source_live_hex,contact_id):
    original,context,_=inspect_packet(original_hex)
    mutated,_,_=inspect_packet(mutated_hex)
    _,_,positions=inspect_live(source_live_hex,context,[])
    need(type(contact_id) is int and roster_ids(context["roster"]).get(contact_id)==1,"mutation opposing contact identity")
    replacement=positions[contact_id]
    book=typed(value_at(value_at(original,"detection"),"contacts"),28,"contact books")[0]
    prior=value_at(value_at(book,contact_id,2),"pos")
    need(prior!=replacement,"wrong-position case must actually change pos")
    expected=replace_at(original,["detection","contacts",0,contact_id,"pos"],replacement)
    need(mutated==expected,"wrong-position packet changed fields other than expected pos")

def verify_source_stability(first_packet,first_live,repaired_packet,repaired_live):
    first,_=bind_capture(first_packet,first_live,[])
    second,_=bind_capture(repaired_packet,repaired_live,[])
    need(first==second,"source simulation projection changed")
    need(decode(first_packet)==decode(repaired_packet),"source packet changed")

def bind_wrong_control(original_hex,mutated_hex,source_live_hex,target_live_hex,contact_id):
    verify_wrong_position(original_hex,mutated_hex,source_live_hex,contact_id)
    target,_=bind_capture(mutated_hex,target_live_hex,[])
    source,_=bind_capture(original_hex,source_live_hex,[])
    need(target["contacts"]!=source["contacts"],"wrong-position target contact did not diverge")

def verify_fixture_identity(packet_hex,expected):
    """Bind the decoded context to an independently approved typed expectation."""
    context=mapping(decode(packet_hex),("format","context","detection","supply"))["context"]
    need(context==decode(expected),"packet context drift from independent fixture expectation")
