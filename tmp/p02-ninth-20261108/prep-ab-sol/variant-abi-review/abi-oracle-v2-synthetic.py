"""Synthetic ABI stdout and streaming boundary checks; does not invoke Godot."""
import struct
from abi_oracle import expected, scalar
from abi_oracle_v2 import BANNER, LIMIT, OutputLimit, verify

def p(fmt,*v):
    return struct.pack("<"+fmt,*v)

def enc(v):
    tag,meta,x=v
    if tag==1:return p("II",1,int(x))
    if tag==2:return p("Iq",2|1<<16,x) if x>=2**31 else p("Ii",2,x)
    if tag==3:
        if struct.unpack("<f",p("f",x))[0]==x:return p("If",3,x)
        return p("Id",3|1<<16,x)
    if tag in (4,21):
        b=x.encode("utf8")
        return p("II",tag,len(b))+b+bytes((-len(b))%4)
    if tag==5:return p("Iff",5,*x)
    if tag in (27,28):
        flags=sum((t is not None)<<(2*i) for i,t in enumerate(meta))
        prefix=p("I",tag|(flags<<16))+b"".join(p("I",t) for t in meta if t is not None)+p("I",len(x))
        return prefix+(b"".join(enc(k)+enc(v) for k,v in x) if tag==27 else b"".join(map(enc,x)))
    raise AssertionError(tag)

oracle=expected()+[("distance-ordered",(28,(None,),tuple(scalar(3,v) for v in (4096.,4096.,4096.00048828125))))]
body=[f"P02_ABI {name} {enc(val).hex()}" for name,val in oracle]
def stdout(rows=body,banner=BANNER):
    return ("\n".join([banner,"",*rows])+"\n").encode()
clean=stdout()
verify(clean,b"",0,None)
print("accepted exact synthetic banner and ten rows")

def reject(name,fn):
    try:fn()
    except (ValueError,UnicodeError) as e:print("rejected",name,str(e))
    else:raise AssertionError(name)

for diagnostic in ("SCRIPT ERROR: parser","ERROR: runtime","WARNING: leaked","unexpected line"):
    reject(diagnostic,lambda:verify(stdout([*body,diagnostic]),b"",0,None))
reject("wrong banner",lambda:verify(stdout(banner="Godot 4.7.2"),b"",0,None))
reject("stdout diagnostic replaces ABI row",lambda:verify(stdout(["ERROR: before outputs",*body[1:]]),b"",0,None))
reject("row duplicate",lambda:verify(stdout([body[0],body[0],*body[2:]]),b"",0,None))
reject("row reordered",lambda:verify(stdout([body[1],body[0],*body[2:]]),b"",0,None))
reject("row missing",lambda:verify(stdout(body[:-1]),b"",0,None))
reject("malformed hex",lambda:verify(stdout(["P02_ABI bool zz",*body[1:]]),b"",0,None))
reject("wrong Variant header",lambda:verify(stdout(["P02_ABI bool 0200000001000000",*body[1:]]),b"",0,None))
reject("stderr",lambda:verify(clean,b"ERROR",0,None))
reject("exit",lambda:verify(clean,b"",1,None))
reject("timeout",lambda:verify(clean,b"",0,"timeout"))
reject("output overflow",lambda:verify(clean+b" "*LIMIT,b"",0,None))
reject("truncated final line",lambda:verify(clean[:-1],b"",0,None))
limiter=OutputLimit(5)
assert limiter.accept(b"abc")==b"abc" and not limiter.exceeded.is_set()
assert limiter.accept(b"def")==b"de" and limiter.exceeded.is_set()
assert limiter.accept(b"xyz")==b""
print("shared streaming cap retains exact allowed prefix and trips overflow")
print("synthetic only")
