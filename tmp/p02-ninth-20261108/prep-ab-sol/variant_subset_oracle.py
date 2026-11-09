"""Strict offline subset of Godot ed1daf0bf Variant payloads used by Q/C."""
import math
import re
import struct

from legacy_autoresolve_oracle import need

def decode(hex_value):
    need(type(hex_value) is str and re.fullmatch(r"(?:[0-9a-f]{2}){4,65536}",hex_value) is not None,"Variant hex")
    data=bytes.fromhex(hex_value)
    offset=0
    def take(size):
        nonlocal offset
        need(0<=size<=len(data)-offset,"Variant truncated")
        part=data[offset:offset+size]
        offset+=size
        return part
    def read(spec):
        return struct.unpack("<"+spec,take(struct.calcsize("<"+spec)))
    def value(depth):
        need(depth<=8,"Variant nesting limit")
        header,=read("I")
        code,flags=header&0xffff,header>>16
        need(flags==0 or (flags==1 and code in (2,3,5)), "Variant unsupported flags")
        if code==2:
            return code,read("q" if flags else "i")[0]
        if code in (3,5):
            fmt="d" if flags else "f"
            values=read(fmt*(2 if code==5 else 1))
            need(all(math.isfinite(x) for x in values),"Variant nonfinite")
            return code,list(values) if code==5 else values[0]
        if code==4:
            size,=read("I")
            result=take(size).decode("utf8")
            need(not any(take((-size)%4)), "Variant string padding")
            return code,result
        if code in (27,28):
            size,=read("I")
            need(size<=64,"Variant container length")
            if code==28:
                return code,[value(depth+1) for _ in range(size)]
            result={}
            for _ in range(size):
                key_type,key=value(depth+1)
                need(key_type==4 and key not in result,"Variant dictionary key")
                result[key]=value(depth+1)
            return code,result
        raise ValueError(f"Variant unsupported type {code}")
    result=value(0)
    need(offset==len(data),"Variant trailing bytes")
    return result

Q_FIELDS=dict(tick=2,side=2,ids=28,kind=4,target_id=2,point=5,args=27)
C_FIELDS=dict(seen=2,state=4,conf_bp=2,pos=5,err_r=3)

def verify_fields(kind, hex_value, fields):
    schema=Q_FIELDS if kind=="q" else C_FIELDS
    container,content=decode(hex_value)
    need(container==27 and content.keys()==schema.keys(),"Variant top-level dictionary schema")
    need(fields.keys()==schema.keys()|{"types"} and fields["types"]==list(schema.values()),"Variant JSON schema or type tags")
    for key,code in schema.items():
        observed,val=content[key]
        need(observed==code,"Variant "+key+" type")
        field=fields[key]
        if key=="ids":
            need(all(t==2 for t,_ in val),"Variant fleet IDs type")
            val=[item for _,item in val]
            need(type(field) is list and all(type(x) is int for x in field),"JSON fleet IDs type")
        elif code==2:
            need(type(field) is int,"JSON integer type")
        elif code==4:
            need(type(field) is str,"JSON string type")
        elif code==5:
            need(type(field) is list and len(field)==2 and all(type(x) in (int,float) for x in field),"JSON vector type")
        elif code==3:
            need(type(field) in (int,float),"JSON float type")
        elif key=="args":
            need(type(field) is dict and not field and not val,"Variant args must be empty")
        need(val==field,"Variant/JSON disagreement: "+key)
