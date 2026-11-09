"""Bounded wire decoder for the C supplement. Unsupported types fail closed."""
import math
import re
import struct

from legacy_autoresolve_oracle import need

def decode_wire(text):
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
        metadata=(flags,) if tag in (3,5) else ()
        if tag==0 and flags==0:
            data=None
        elif tag==1 and flags==0:
            bit,=read("I")
            need(bit in (0,1),"Variant boolean")
            data=bool(bit)
        elif tag==2 and flags in (0,1):
            data=read("q" if flags else "i")[0]
            need(flags == int(not -(2**31) <= data < 2**31), "noncanonical Variant integer width")
        elif tag in (3,5) and flags in (0,1):
            values=read(("d" if flags else "f")*(2 if tag==5 else 1))
            need(all(math.isfinite(v) for v in values),"Variant nonfinite")
            data=values if tag==5 else values[0]
            if tag==3 and flags:
                try:
                    narrowed=struct.unpack("<f", struct.pack("<f", data))[0]
                except OverflowError:
                    narrowed=math.copysign(math.inf, data)
                need(narrowed != data, "noncanonical Variant float width")
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


