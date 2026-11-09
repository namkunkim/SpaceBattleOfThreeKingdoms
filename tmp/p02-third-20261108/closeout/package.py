from pathlib import Path
import hashlib,json,zipfile
root=Path.cwd()
e=Path("tmp/p02-third-20261108")
out=e/"closeout"
zip_path=Path("tmp/P02-REPLAY-DELIVERY-20261108.zip")
manifest_path=out/"manifest.json"
verification_path=out/"archive-verification.json"
assert not any(p.exists() for p in (zip_path,manifest_path,verification_path))
def load(p): return json.loads(p.read_text(encoding="utf8"))
def sha(data): return hashlib.sha256(data).hexdigest()
def write(p,data): p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
audit=load(out/"preservation.json")
assert all(audit["checks"].values())
d=Path("docs/battle-core/pc-campaign-design")
owned=[Path("tests/autoresolve.gd"),Path("core/battle/operation_replay.gd"),Path("tests/p02_replay_adapter.gd"),*Path("tests/fixtures/p02").glob("replay-*.json"),*(Path(name) for name in audit["delta"] if name.startswith("docs/"))]
references=[Path("tmp/i01b-followup-20261028/logs/battle_flow-output.log"),*(p for p in Path("tests/fixtures/p02").glob("*.json") if not p.name.startswith("replay-"))]
evidence=[p for p in e.rglob("*") if p.is_file()]
files=sorted(set(owned+references+evidence))
records={p.as_posix():{"bytes":p.stat().st_size,"sha256":sha(p.read_bytes()),"role":"delivery source/document" if p in owned else "read-only comparison reference" if p in references else "evidence"} for p in files}
manifest={"scope":"restricted fresh replay CLI only; product consumer integration pending", "p02_i01_i01b_a04_a06":"NOT_READY","external_save_schema":"UNCLASSIFIED","engine":"Godot 4.7.2.stable.official.ed1daf0bf","repo_dependencies":"Shared runtime, scenes, dependencies and Godot executable come from the recorded checkout and engine installation.","implementation_review":"limited acceptance","closeout_review":"pending","final_gate":{"attempt2_passed":74,"attempt2_processes":75,"attempt3_single_retest_passed":True,"final_cases":75,"attempts_actual_processes":150,"comparisons":36},"prior_deliveries":"preserved; this ZIP is newly created","archive_members":records}
write(manifest_path,manifest)
with zipfile.ZipFile(zip_path,"x",zipfile.ZIP_DEFLATED,compresslevel=7) as archive:
 for path in files+[manifest_path]: archive.write(path,path.as_posix())
with zipfile.ZipFile(zip_path) as archive:
 names=archive.namelist()
 assert archive.testzip() is None
 assert len(names)==len(set(names)) and set(names)==set(records)|{manifest_path.as_posix()}
 assert archive.read(manifest_path.as_posix())==manifest_path.read_bytes()
 for name,data in records.items():
  item=archive.read(name)
  assert len(item)==data["bytes"] and sha(item)==data["sha256"] and sha(Path(name).read_bytes())==data["sha256"],name
write(verification_path,{"archive":zip_path.as_posix(),"archive_sha256":sha(zip_path.read_bytes()),"archive_bytes":zip_path.stat().st_size,"manifest_sha256":sha(manifest_path.read_bytes()),"member_count_including_manifest":len(names),"member_byte_hash_matches":len(names),"crc":True,"unique_exact_member_set":True})
print(verification_path.read_text())
