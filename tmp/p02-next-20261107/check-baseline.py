from pathlib import Path
import hashlib,json,subprocess
e=Path("tmp/p02-next-20261107")
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
rows=json.loads((e/"baseline-files.json").read_text(encoding='utf-8'))
for row in rows:
 p=Path(row["path"])
 if row["path"] in ["scripts/world/auto_resolver.gd","tests/autoresolve.gd"]: p=e/"before"/(p.name+".txt")
 if not p.is_file() or p.stat().st_size != row["bytes"] or sha(p)!=row["sha256"]: print(row["path"])

