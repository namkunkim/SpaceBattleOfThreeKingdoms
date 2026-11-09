import hashlib, json, pathlib
p=pathlib.Path(__file__).parent
a,b=[json.loads((p/f"baseline-longpaths-0{i}.json").read_text(encoding="utf-8")) for i in (2,3)]
ak,bk=[set(x["paths"]) for x in (a,b)]
changed=[k for k in sorted(ak&bk) if a["paths"][k]!=b["paths"][k]]
out={"same_meta":a["after"]==b["before"],"added":sorted(bk-ak),"removed":sorted(ak-bk),"changed":changed,"scan_drift":[a["list_drift"],b["list_drift"]],"sha":{}}
for name in ["baseline.json","baseline-longpaths-02.json","baseline-longpaths-03.json","PLAN.md","freeze.py"]:
 with (p/name).open("rb") as f: out["sha"][name]=hashlib.file_digest(f,"sha256").hexdigest()
(p/"baseline-comparison.json").write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding="utf-8")
print(json.dumps(out,ensure_ascii=False,indent=2))
