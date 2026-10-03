import sys, json, simd
from simd import *
from final3 import C
from dr import RXKW
diff = sys.argv[1]; seed = int(sys.argv[2]); dp = json.loads(sys.argv[3]); kw = json.loads(sys.argv[4]) if len(sys.argv) > 4 else {}
simd.DP.update(dp); MS.DIFF["표준"]["start_morale_bp"]["northern"] = 8000
setup_diff(diff, {})
print("HOST", HOST)
r = run(dict(BASE, **C(**dict(RXKW, **kw)), chain=True, susp_rate=SUSP[diff], detection=True), seed)
print(r["reason"], round(r["t"]/60, 1), "win", round(r["win_start"]/60, 1) if r["win_start"] else None, r["fconf"], r["fest"], r["shots"])
print(" ; ".join(f"{t/60:.1f} {k} {x.replace('RC-','')}" for t, k, x in sorted(r["ev"]) if k not in ("escape",)))
