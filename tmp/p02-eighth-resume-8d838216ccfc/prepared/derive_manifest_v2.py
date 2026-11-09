from pathlib import Path
p=Path(__file__).resolve().parent
s=(p/"make_manifest.py").read_text(encoding="utf-8-sig")
s=s.replace("from overlays import overlays","from overlays_v2 import overlays, SUITES")
s=s.replace('"deployment.gd"','"deployment_v2.gd"').replace('"native.gd"','"native_v2.gd"').replace('"rejection.gd"','"rejection_v2.gd"')
s=s.replace('for row, case in ((9,"contract")','job(9,"after","contract",HERE/"rejection_v2.gd",120,("after","contract","{raw}"),RETURNING)\n\nfor row, case in ((9,"contract")')
s=s.replace('"make_manifest.py", "ORACLES.md"','"make_manifest.py", "make_manifest_v2.py", "runner_v2.py", "overlays_v2.py", "derive_v2.py", "ORACLES.md", "ORACLES-V2.md"')
s=s.replace('"MANIFEST-REVIEW-ONLY.json"','"MANIFEST-V2-REVIEW-ONLY.json"')
s=s.replace('    j["row_ids"] =','    j["assertion_index"] = "ordinal and original label from K6_SUITE_ASSERT" if j["case_id"] in SUITES or j["row_id"] in (19, 20) else "ASSERT labels and typed records per ORACLES.md and ORACLES-V2.md"\n    j["row_ids"] =')
with (p/"make_manifest_v2.py").open("x", encoding="utf-8") as f:
    f.write(s)
