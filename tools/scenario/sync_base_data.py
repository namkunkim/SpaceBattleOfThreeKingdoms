"""본편 data/의 적벽 전투 기준 데이터를 data/scenarios/base/로 복사한다(M2b).
복사만 한다. 값을 고치지 않는다. 출처 커밋과 파일 해시를 MANIFEST.json에 남긴다.
실행: python tools/scenario/sync_base_data.py  (본편 경로는 SRC)
"""
import hashlib, json, shutil, subprocess
from pathlib import Path

SRC = Path(r"C:\WorkSpace\Seonghanji")
OUT = Path(__file__).resolve().parent.parent.parent / "data" / "scenarios" / "base"
FILES = ["ship-types.json", "formations.json", "red-cliffs-demo-setup.json"] + sorted(
    p.name for p in (SRC / "data").glob("red-cliffs-*-rules.json"))

OUT.mkdir(parents=True, exist_ok=True)
manifest = {"source": str(SRC), "files": {}}
try:
    manifest["source_head"] = subprocess.check_output(
        ["git", "-C", str(SRC), "rev-parse", "HEAD"], text=True).strip()
    manifest["source_dirty"] = bool(subprocess.check_output(
        ["git", "-C", str(SRC), "status", "--porcelain", "--"] + [f"data/{f}" for f in FILES], text=True).strip())
except Exception as e:
    manifest["source_head"] = f"unknown ({e})"
for f in FILES:
    shutil.copyfile(SRC / "data" / f, OUT / f)
    manifest["files"][f] = hashlib.sha256((OUT / f).read_bytes()).hexdigest()[:16]
(OUT / "MANIFEST.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=1), encoding="utf-8")
print(len(FILES), "files ->", OUT)
