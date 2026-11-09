"""Verify and map source-only C rows without replacing their original evidence."""
import hashlib
import json
from pathlib import Path

from c_side1_bound_v4 import fields,integer
from c_side1_chain_v6 import valid_sha
from c_side1_semantics_v8 import decode,mapping
from legacy_autoresolve_oracle import need,unique

PREFIX=b"K6_C_PRODUCER "
PHASES=("estimated/primary","estimated/repeat","wrong-position-control","estimated repaired/primary","estimated repaired/repeat")

def phase_ids(case):
    need(case in ("estimated","lost"),"case")
    return tuple(p.replace("estimated",case) for p in PHASES)

def evidence(path, receipt, approved_producer_sha):
    fields(receipt,("lane","run_id","pid","created","producer_sha","raw_sha"),"independent launcher receipt")
    need(type(receipt["lane"]) is str and receipt["lane"] in ("before","after"),"launcher lane")
    need(type(receipt["run_id"]) is str and bool(receipt["run_id"]),"launcher run")
    need(integer(receipt["pid"],"launcher PID")>0 and integer(receipt["created"],"creation")>0,"owned process identity")
    valid_sha(approved_producer_sha,"approved producer SHA")
    need(receipt["producer_sha"]==approved_producer_sha,"producer pin")
    raw=Path(path).read_bytes()
    need(hashlib.sha256(raw).hexdigest()==receipt["raw_sha"],"raw stream drift")
    prior=-1
    offset=0
    rows=[]
    for line in raw.splitlines(keepends=True):
        if line.startswith(PREFIX):
            need(line.endswith(b"\n"),"unterminated producer line")
            row=json.loads(line[len(PREFIX):],object_pairs_hook=unique)
            fields(row,("stream_ordinal","mono_usec","sim_id","actor","case","seed","tick","event","phase","payload_hex"),"raw producer row")
            integer(row["stream_ordinal"],"single writer ordinal",len(rows))
            mono=integer(row["mono_usec"],"monotonic microseconds")
            need(mono>=0 and mono>=prior,"producer clock regression")
            prior=mono
            # Equal microsecond readings remain equal. Sequence is independent.
            rows.append(dict(row,mono_ns=mono*1000,offset=offset,line_sha=hashlib.sha256(line).hexdigest(),
                             lane=receipt["lane"],run_id=receipt["run_id"],pid=receipt["pid"],created=receipt["created"]))
        offset+=len(line)
    need(bool(rows),"missing producer rows")
    return rows

def restore_pairs(rows,seed,case):
    matched=[r for r in rows if r["seed"]==seed and r["case"]==case and r["event"] in (
        "source-before","restore-request","restore-result","source-after")]
    need(len(matched)==20,"five restore calls and four raw boundaries per call")
    sources=set()
    targets=set()
    pairs=[]
    for i,phase in enumerate(phase_ids(case)):
        a,request,result,b=matched[4*i:4*i+4]
        ordered=(a,request,result,b)
        need(tuple(r["event"] for r in ordered)==("source-before","restore-request","restore-result","source-after"),"restore raw event order")
        need(tuple(r["actor"] for r in ordered)==("native-source","restore-target","restore-target","native-source"),"restore actor order")
        need(len({r["tick"] for r in ordered})==1 and all(r["phase"]==phase for r in ordered),"restore tick or phase drift")
        need(len({(r["run_id"],r["lane"],r["pid"],r["created"]) for r in ordered})==1,"mixed restore process")
        need(a["sim_id"]==b["sim_id"] and request["sim_id"]==result["sim_id"],"restore simulation identity changed")
        sources.add(a["sim_id"])
        targets.add(request["sim_id"])
        raw_before=mapping(decode(request["payload_hex"]),("state","packet"))
        raw_after=mapping(decode(result["payload_hex"]),("state","packet","result"))
        need(raw_before["packet"]==raw_after["packet"],"restore mutated typed packet")
        source_before=mapping(decode(a["payload_hex"]),("state",))["state"]
        source_after=mapping(decode(b["payload_hex"]),("state",))["state"]
        need(source_before==source_after,"restore mutated source _all")
        target_before=mapping(raw_before["state"],("outside","selected"))
        target_after=mapping(raw_after["state"],("outside","selected"))
        need(target_before["outside"]==target_after["outside"],"restore mutated target outside")
        if phase.endswith("/repeat"):
            need(raw_before["state"]==raw_after["state"],"repeat restore not a no-op")
        need(mapping(raw_after["result"],("ok",))["ok"]==(1,(),True),"actual restore result")
        pairs.append({"phase":phase,"request_offset":request["offset"],"result_offset":result["offset"],
                      "request_line_sha":request["line_sha"],"result_line_sha":result["line_sha"]})
    need(len(sources)==len(targets)==1 and not sources&targets,"cross-call simulation identity mismatch")
    return pairs
