"""Synthetic test for raw producer mapping; never launches a process."""
import hashlib
import json
from pathlib import Path
import struct
from tempfile import TemporaryDirectory

from c_raw_overlay_mapping import evidence,phase_ids,restore_pairs

def encode(value):
    if type(value) is bool:
        return struct.pack("<II",1,value)
    if type(value) is int:
        return struct.pack("<Ii",2,value)
    if type(value) is str:
        data=value.encode()
        return struct.pack("<II",4,len(data))+data+bytes((-len(data))%4)
    if type(value) is dict:
        return struct.pack("<II",27,len(value))+b"".join(encode(k)+encode(v) for k,v in value.items())
    raise ValueError(type(value))

def make_rows():
    rows=[]
    state={"outside":{"t":320},"selected":{"dummy":1}}
    for phase in phase_ids("estimated"):
        for event,actor,id,payload in (
            ("source-before","native-source",1,{"state":state}),
            ("restore-request","restore-target",2,{"state":state,"packet":{"dummy":1}}),
            ("restore-result","restore-target",2,{"state":state,"packet":{"dummy":1},"result":{"ok":True}}),
            ("source-after","native-source",1,{"state":state})):
            rows.append(dict(stream_ordinal=len(rows),mono_usec=100,sim_id=id,actor=actor,case="estimated",seed=0,
                             tick=320,event=event,phase=phase,payload_hex=encode(payload).hex()))
    return rows

def reject(name,operation):
    try:operation()
    except ValueError as error:print("rejected",name,str(error))
    else:raise AssertionError(name)

with TemporaryDirectory(dir=Path(__file__).resolve().parent) as folder:
    path=Path(folder)/"raw.log"
    def parse(rows):
        data=b"".join(b"K6_C_PRODUCER "+json.dumps(r).encode()+b"\n" for r in rows)
        path.write_bytes(data)
        return evidence(path,dict(lane="before",run_id="synthetic",pid=33,created=22,producer_sha="a"*64,
                                  raw_sha=hashlib.sha256(data).hexdigest()),"a"*64)
    rows=make_rows()
    result=parse(rows)
    assert all(row["mono_ns"]==100000 for row in result)
    assert len(restore_pairs(result,0,"estimated"))==5
    print("accepted five original pairs and equal true timestamps")
    reject("missing repeat restore",lambda:restore_pairs(result[:4]+result[8:],0,"estimated"))
    bad=make_rows()
    bad[7]["payload_hex"]=encode({"state":{"outside":{"t":321},"selected":{"dummy":1}}}).hex()
    reject("source state mutated",lambda:restore_pairs(parse(bad),0,"estimated"))
    bad=make_rows()
    bad[6]["payload_hex"]=encode({"state":{"outside":{"t":320},"selected":{"dummy":2}},
                                 "packet":{"dummy":1},"result":{"ok":True}}).hex()
    reject("repeat changed selected state",lambda:restore_pairs(parse(bad),0,"estimated"))
    bad=make_rows()
    bad[0]["stream_ordinal"]=1
    reject("producer ordinal forged",lambda:parse(bad))
print("synthetic only")
