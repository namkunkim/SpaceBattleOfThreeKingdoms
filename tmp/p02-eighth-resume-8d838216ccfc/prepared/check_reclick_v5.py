from pathlib import Path
import json
import sys
sys.dont_write_bytecode = True
from world_product_v5 import assess, RECLICK
p=Path(__file__).resolve().parent
dest=p/"v5-synthetic"
past=p/"v4-synthetic/cancel-before.json"
records=json.loads(past.read_bytes())
ids=[r["assertion"] for r in records]+list(RECLICK)
complete=records+[{"assertion":k,"ok":True,"details":v if v is not None else {"path":"/synthetic/control","rect":"synthetic"}} for k,v in RECLICK.items()]
def save(name,data):
    f=dest/name
    with f.open("x",encoding="utf-8") as out:
        json.dump(data,out,ensure_ascii=False)
    return f
good=save("reclick-good.json",complete)
bad=save("reclick-absent.json",records)
assert not assess([good,good],True,ids)
assert assess([good,bad],True,ids)
print("synthetic reclick pair accepted, missing second cycle rejected")
