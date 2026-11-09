"""Read-only ABI probe comparator. Does not invoke an engine."""
from pathlib import Path
import sys

sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from c_side1_semantics_v8 import decode
from legacy_autoresolve_oracle import need

def scalar(tag,value):
    return tag,(),value

def dictionary(entries,metadata=(None,None)):
    return 27,metadata,tuple(entries)

def array(entries,metadata=(None,)):
    return 28,metadata,tuple(entries)

def expected():
    integer=lambda n:scalar(2,n)
    string=lambda n:scalar(4,n)
    vector=lambda x,y:scalar(5,(x,y))
    contact=dictionary([(string("seen"),integer(11)),(string("pos"),vector(500,450)),
        (string("state"),string("estimated")),(string("conf_bp"),integer(5000)),(string("err_r"),scalar(3,30.0))])
    nested=dictionary([(string("active"),scalar(1,True)),(string("contacts"),
        array((dictionary([(integer(15),contact)]),dictionary([]))))])
    return [
        ("bool",scalar(1,True)),("int64",integer(4294967296)),("f32",scalar(3,1.5)),
        ("f64",scalar(3,0.1)),("string-name",scalar(21,"abi-probe")),("vector2",vector(4096,1)),
        ("typed-array",array((integer(7),integer(15)),(2,))),
        ("typed-dict",dictionary([(integer(15),vector(1500,450)),(integer(7),vector(400,450))],(2,5))),
        ("ordered-contact",nested),
    ]

def check(stdout,stderr):
    need(not stderr.strip(),"nonempty stderr")
    rows=[]
    for line in stdout.splitlines():
        if not line.startswith("P02_ABI "):
            continue
        _,name,payload=line.split(" ",2)
        rows.append((name,payload))
    oracle=expected()
    need(len(rows)==len(oracle)+1,"ABI required row count")
    for (name,hex_value),(wanted,value) in zip(rows,oracle):
        need(name==wanted and decode(hex_value)==value,f"ABI mismatch: {wanted}")
    by_name=dict(rows)
    need(bytes.fromhex(by_name["int64"])[:4]==bytes.fromhex("02000100"),"int64 width flag")
    need(bytes.fromhex(by_name["f32"])[:4]==bytes.fromhex("03000000"),"f32 width flag")
    need(bytes.fromhex(by_name["f64"])[:4]==bytes.fromhex("03000100"),"f64 width flag")
    name,hex_value=rows[-1]
    need(name=="distance-ordered","distance row")
    tag,meta,values=decode(hex_value)
    need(tag==28 and meta==(None,) and len(values)==3 and all(r[0]==3 for r in values),"distance float tuple")
    a,b,c=(r[2] for r in values)
    need(a==b==4096.0 and c>b,"engine precision/tie differs from approved float32 model")

if __name__=="__main__":
    if len(sys.argv)!=3:
        raise SystemExit("usage: abi_oracle.py STDOUT STDERR")
    check(*(Path(p).read_text(encoding="utf8") for p in sys.argv[1:]))
    print("ABI rows 10/10; no product assertion")
