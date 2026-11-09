from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import hashlib,json,os,subprocess,sys,zipfile

root=Path.cwd()
old=Path("tmp/p02-fourth-20261108")
reb=old/"rebaseline-1"
out=old/"closeout"
docs=Path("docs/battle-core/pc-campaign-design")
progress=docs/"P02-PROGRESS-CHECKLIST.md"
requirements=docs/"SESSION-REQUIREMENTS-CHECKLIST-20261031.md"
master=Path("docs/battle-core/CHECKLIST-OPEN.md")
result=docs/"P02-VIEWER-EVENTS-RESULT-20261108.md"
checklist=docs/"P02-VIEWER-EVENTS-CHECKLIST-20261108.md"
handoff=docs/"SESSION-HANDOFF-P02-VIEWER-EVENTS-20261108.md"
archive=Path("tmp/P02-VIEWER-EVENTS-DELIVERY-20261108.zip")
review=old/"REVIEW-5B-REBASELINE-INDEPENDENT.md"
owner=Path("core/battle/operation_private_state.gd")
runner=Path("tests/p02_viewer_events.gd")
updated=(progress,requirements,master)
created=(result,checklist,handoff)
accept="e5d0b3530d377ac045d437854f0bd14925ec1b0eade9a6992bd4cd55952485b7"
def dump(p,value):
    p.write_text(json.dumps(value,indent=2,ensure_ascii=False)+"\n",encoding="utf8")
def read(p):return json.loads(p.read_bytes())
def digest(b):return hashlib.sha256(b).hexdigest()
def info(p):
    with p.open("rb") as f:
        return {"bytes":p.stat().st_size,"sha256":hashlib.file_digest(f,"sha256").hexdigest()}
def git(*args):
    return subprocess.check_output(["git",*args],env={**os.environ,"GIT_OPTIONAL_LOCKS":"0"})
def identity():
    b=read(old/"baseline.json")
    return (git("branch","--show-current").decode().strip()==b["branch"] and git("rev-parse","HEAD").decode().strip()==b["head"]
            and git("ls-files","-s","-z")== (old/"index.raw").read_bytes() and info(Path(".git/index"))["sha256"]==b["index_file_sha256"])
def inventory():
    names={Path(p) for p in (git("ls-files","-z")+git("ls-files","--others","--exclude-standard","-z")).decode().split("\0") if p}
    names.update(p for p in old.rglob("*") if p.is_file())
    names.update((Path(".godot/global_script_class_cache.cfg"),Path(".godot/uid_cache.bin")))
    names=sorted(p for p in names if not p.is_relative_to(out))
    with ThreadPoolExecutor(12) as pool:
        return {p.as_posix():r for p,r in zip(names,pool.map(info,names))}
def splice(p,old_bytes,new_bytes):
    original=p.read_bytes()
    newline=b"\r\n" if b"\r\n" in original else b"\n"
    anchor=old_bytes.encode().replace(b"\n",newline)
    changed=new_bytes.encode().replace(b"\n",newline)
    assert original.count(anchor)==1
    new=original.replace(anchor,changed,1)
    assert new.count(changed)==1 and new.replace(changed,anchor,1)==original
    return original,new,anchor,changed

def author():
    assert info(review)["sha256"]==accept and read(reb/"verdict.json")["passed"] and read(reb/"additional-protection.json")["passed"]
    assert identity() and not archive.exists() and all(not p.exists() for p in created)
    current=inventory()
    prior=read(reb/"workspace-after.json")
    drift={p for p,v in prior.items() if current.get(p)!=v}
    if drift: raise RuntimeError(f"unapproved workspace drift: {sorted(drift)}")
    dump(out/"workspace-before.json",current)
    changes={}
    section="""## 한정 수용 완료 — private owner 표시용 사건 회수

- [x] 제한 private owner가 정수 0/1을 받아 기존 안개 규칙대로 사건을 회수한다. 공유 큐 소진·실패 불변·반환 사본을 native와 대조했다. 독립 재심에서 한정 수용됐다. 기본 17개, 신규 검사 14행·148개 단언, 격리 보완 회귀 14개와 탐침 3개를 별도로 기록한다. 실제 제품 호스트 연결은 남은 인수에 해당한다. [결과](P02-VIEWER-EVENTS-RESULT-20261108.md) · [전용 체크리스트](P02-VIEWER-EVENTS-CHECKLIST-20261108.md) · [최신 인계](SESSION-HANDOFF-P02-VIEWER-EVENTS-20261108.md) · [독립 재심](../../../tmp/p02-fourth-20261108/REVIEW-5B-REBASELINE-INDEPENDENT.md)

"""
    changes[progress]=splice(progress,"## 남은 인수",section+"## 남은 인수")
    a="[제한 fresh replay CLI](P02-REPLAY-RESULT-20261108.md) 구현 한정 수용."
    changes[requirements]=splice(requirements,a,"[제한 fresh replay CLI](P02-REPLAY-RESULT-20261108.md) 및 [private owner 표시용 사건 회수](P02-VIEWER-EVENTS-RESULT-20261108.md) 구현 한정 수용.")
    raw=master.read_text(encoding="utf8")
    line=next(line for line in raw.splitlines() if "**P02 제한 fresh replay CLI(2026-11-08):**" in line)
    new="  - [ ] **P02 private owner 표시용 사건 회수(2026-11-08):** 독립 재심에서 한정 수용됐다. 기본 17개, 신규 검사 14행·148개 단언, 격리 회귀 14개와 탐침 3개를 확인했다. 전체 P02는 NOT_READY이며 제품 호스트 연결과 공동 인수는 남는다. [결과](pc-campaign-design/P02-VIEWER-EVENTS-RESULT-20261108.md) · [진행표](pc-campaign-design/P02-PROGRESS-CHECKLIST.md) · [최신 인계](pc-campaign-design/SESSION-HANDOFF-P02-VIEWER-EVENTS-20261108.md)."
    changes[master]=splice(master,line,line+"\n"+new)
    assert all(info(p)==current[p.as_posix()] for p in updated) and identity()
    proof={}
    for p,(before,after,anchor,changed) in changes.items():
        backup=out/(p.name+".before")
        backup.write_bytes(before)
        p.write_bytes(after)
        recovered=p.read_bytes().replace(changed,anchor,1)
        assert recovered==before
        proof[p.as_posix()]={"before":info(backup),"after":info(p),"reverse_sha256":digest(recovered),"original_span_hex":anchor.hex(),"updated_span_hex":changed.hex()}
    for p in created:
        p.write_bytes((out/(p.name+".draft")).read_bytes())
    dump(out/"document-proof.json",proof)

def audit(label,with_zip):
    assert identity()
    before=read(out/"workspace-before.json")
    current=inventory()
    changed={p for p,v in before.items() if current.get(p)!=v}
    additions=set(current)-set(before)
    wanted={p.as_posix() for p in created}
    if with_zip: wanted.add(archive.as_posix())
    assert changed=={p.as_posix() for p in updated},sorted(changed)
    assert additions==wanted,sorted(additions)
    proof=read(out/"document-proof.json")
    for p in updated:
        r=proof[p.as_posix()]
        raw=p.read_bytes()
        span=bytes.fromhex(r["updated_span_hex"])
        assert raw.count(span)==1 and digest(raw.replace(span,bytes.fromhex(r["original_span_hex"]),1))==r["before"]["sha256"]
    assert owner.read_bytes().replace((old/"owned-hunk.gd.txt").read_bytes(),b"",1)==(old/"owner.before.gd.txt").read_bytes()
    proc=subprocess.run(["git","diff","--check"],capture_output=True,env={**os.environ,"GIT_OPTIONAL_LOCKS":"0"})
    assert proc.returncode==2 and proc.stdout.splitlines()==(old/"diff-check-before.stdout").read_bytes().splitlines()
    (out/(label+"-diff-check.stdout")).write_bytes(proc.stdout)
    (out/(label+"-diff-check.stderr")).write_bytes(proc.stderr)
    dump(out/(label+".json"),{"protected_count":len(before),"existing_owned_doc_delta":sorted(changed),"new_owned":sorted(additions),
         "branch_head_index_match":identity(),"p03_protected":sum("p03" in p.lower() for p in before),"prior_zips_protected":sum(p.lower().endswith(".zip") for p in before),
         "workspace_diff_check_actual_exit":proc.returncode,"workspace_diff_check_baseline_match":True,
         "document_reverse_match":True,"owner_reverse_match":True})
def package():
    assert not archive.exists()
    files={*updated,*created,owner,runner,Path("tmp/i01b-followup-20261028/logs/battle_flow-output.log"),
           *Path("tests/fixtures/p02").glob("*.json"),*(p for p in old.rglob("*") if p.is_file() and not p.is_relative_to(reb) and not p.is_relative_to(out))}
    for p in reb.rglob("*"):
        if not p.is_file(): continue
        rel=p.relative_to(reb)
        if rel.parts[0] in ("isolated-before","isolated-after"):
            if rel.as_posix().endswith(("attempt1-observations.json","attempt2-observations.json")): files.add(p)
        else: files.add(p)
    files.update(p for p in out.iterdir() if p.is_file() and not p.name.endswith(".draft"))
    manifest=out/"manifest.json"
    assert not manifest.exists()
    members={p.as_posix():info(p) for p in sorted(files)}
    dump(manifest,{"scope":"restricted private owner viewer drain","overall":"NOT_READY","external_save_schema":"UNCLASSIFIED",
                   "independent_implementation_reacceptance_sha256":accept,"independent_closeout_at_packaging":"pending",
                   "canonical_processes":17,"viewer_logical_rows":14,"viewer_assertions":148,"isolated_regressions":14,"isolation_probes_actual":3,
                   "retained_legacy_evidence":"Includes rejected/failing baseline and later isolated correction.",
                   "dependencies":"Requires the recorded checkout and engine. Isolated project input copies are represented by exact per-path manifests, not included wholesale.",
                   "archive_members":members})
    with zipfile.ZipFile(archive,"x",zipfile.ZIP_DEFLATED,compresslevel=7) as z:
        for p in sorted(files|{manifest}): z.write(p,p.as_posix())
    with zipfile.ZipFile(archive) as z:
        names=z.namelist()
        assert z.testzip() is None and set(names)==set(members)|{manifest.as_posix()} and len(names)==len(set(names))
        assert z.read(manifest.as_posix())==manifest.read_bytes()
        for name,r in members.items():
            b=z.read(name)
            assert len(b)==r["bytes"] and digest(b)==r["sha256"] and info(Path(name))==r,name
    dump(out/"archive-verification.json",{"archive":archive.as_posix(),**info(archive),"manifest":info(manifest),
          "member_count_including_manifest":len(names),"member_byte_hash_matches":len(names),"crc":True,"unique_exact_member_set":True})

if __name__=="__main__":
    if sys.argv[1]=="author":author()
    if sys.argv[1]=="package":
        audit("preservation-pre-package",False)
        package()
        audit("preservation-post-package",True)
