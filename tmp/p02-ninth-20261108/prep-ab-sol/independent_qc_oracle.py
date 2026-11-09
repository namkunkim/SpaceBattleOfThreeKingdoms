"""Secondary source-derived Q/C oracle for review-only capture refinements."""
import argparse
import json
import math
import struct
from pathlib import Path
from legacy_autoresolve_oracle import need, same, unique, constant
from qc_capture_streams import extract, check

COMMAND_TYPES = [2,2,28,4,2,5,27]
RECORD_TYPES = [2,4,2,5,3]

def records(stdout, prefix):
    return [json.loads(line[len(prefix):], object_pairs_hook=unique, parse_constant=constant)
            for line in stdout.splitlines() if line.startswith(prefix)]

def f32(value):
    return struct.unpack("<f", struct.pack("<f", value))[0]

def distance(a,b):
    x,y=(f32(u-v) for u,v in zip(a,b))
    return f32(math.sqrt(f32(f32(x*x)+f32(y*y))))

def policy(projection):
    need(projection["hz"] == 10, "Q fixture hz")
    roster=projection["roster"]
    ids=[r["id"] for r in roster]
    need(len(set(ids))==len(ids), "Q duplicate fleet ID")
    for row in roster:
        need(row["types"][:3]==[2,2,5] and type(row["id"]) is int and row["side"] in (0,1), "Q fleet identity/type")
        need(len(row["pos"]) == 2 and all(type(x) in (int,float) and math.isfinite(x) for x in row["pos"]), "Q position")
        need(type(row["contact"]) is str or type(row["dead"]) is bool, "Q exposure")
    if not projection["case"].endswith("/attack5") or projection["tick"]%50:
        return []
    allies=[r for r in roster if r["side"]==0 and r["dead"] is False]
    foes=[r for r in roster if r["side"]==1 and (r["contact"] in ("confirmed","estimated") if r["contact"] is not None else r["dead"] is False)]
    def command(ids,kind,target=-1):
        return dict(tick=-1,side=0,ids=ids,kind=kind,target_id=target,point=[0,0],args={},types=COMMAND_TYPES)
    if not allies:
        return []
    result=[]
    for ally in allies:
        target=None
        best=1e9
        for foe in foes:
            d=distance(ally["pos"],foe["pos"])
            if d<best:
                best=d
                target=foe["id"]
        if target is not None:
            result.append(command([ally["id"]],"attack",target))
    return result+[command([r["id"] for r in allies],kind) for kind in ("missile","fighter")]

def check_q(stdout):
    expected,actual=extract("q",stdout)
    projections=records(stdout,"K6_Q_INDEPENDENT ")
    need(len(projections)==len(actual), "Q independent projection count")
    for item, projection in zip(actual,projections):
        need(all(item[k]==projection[k] for k in ("seed","tick","case")), "Q projection key drift")
        want=policy(projection)
        got=[r["fields"] for r in item["commands"]]
        need(len(want)==len(got), "Q independently computed command count")
        for reference, observation in zip(want,got):
            # Godot JSON may spell Vector2 scalar zero with or without a decimal.
            point=observation["point"]
            need(type(point) is list and len(point)==2 and all(type(v) in (int,float) and v==0 for v in point),"Q command point")
            same(reference,dict(observation,point=[0,0]))
    stripped=[[dict(row,commands=[{k:v for k,v in entry.items() if k!="fields"} for entry in row["commands"]]) for row in stream] for stream in (expected,actual)]
    check("q",*stripped)

def scalar(item):
    kind=item["type"]
    if kind in ("String","int"):
        return item["value"]
    if kind=="Vector2":
        return [scalar(item["x"]),scalar(item["y"])]
    need(kind=="float","C historical float type")
    raw=bytes.fromhex(item["bytes"])
    need(len(raw) in (8,12) and int.from_bytes(raw[:4],"little") & 0xffff == 3,"C historical float encoding")
    return struct.unpack("<f" if len(raw)==8 else "<d",raw[4:])[0]

def historical_cases(path):
    doc=json.loads(path.read_bytes(),object_pairs_hook=unique)
    return {(row["seed"],row["kind"]):{e["key"]["value"]:scalar(e["value"]) for e in row["record"]["entries"]}
            for row in doc["cases"] if row["kind"] in ("estimated","lost")}

def check_c(stdout,historical):
    expected,actual=extract("c",stdout)
    successes=records(stdout,"K6_C_RESTORE ")
    want=[dict(seed=row["seed"],phase=row["phase"],ok=True) for row in expected if row["side"]==0]
    same(want,successes)
    for stream in (expected,actual):
        for row in stream:
            # Fixture builds one ally (id 1) and one foe (id 2).
            ids=[record["id"] for record in row["records"]]
            need(ids==[2] if row["side"]==0 else ids in ([],[1]), "C invalid fixture opposing IDs")
            for item in row["records"]:
                fields=item["fields"]
                need(fields["types"]==RECORD_TYPES,"C contact Variant types")
                if row["side"]==0:
                    baseline=historical[(row["seed"],row["phase"].split()[0])]
                    for k,v in baseline.items():
                        need(fields[k]==v, f"C historical fixture contact field: {k}")
    same(expected,actual)
    stripped=[[dict(row,records=[{k:v for k,v in entry.items() if k!="fields"} for entry in row["records"]]) for row in stream] for stream in (expected,actual)]
    check("c",*stripped)

if __name__=="__main__":
    cli=argparse.ArgumentParser(description=__doc__)
    cli.add_argument("kind",choices=("q","c"))
    cli.add_argument("stdout",type=Path)
    cli.add_argument("--historical-service",type=Path)
    args=cli.parse_args()
    raw=args.stdout.read_text(encoding="utf-8-sig")
    if args.kind=="q":
        check_q(raw)
    else:
        need(args.historical_service is not None,"C frozen historical fixture record source required")
        check_c(raw,historical_cases(args.historical_service))
