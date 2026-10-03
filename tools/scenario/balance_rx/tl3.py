import sys, json
from sim3 import *
from final3 import C
diff = sys.argv[1]; seed = int(sys.argv[2]); kw = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}
setup_diff(diff, {})
r = run(dict(BASE, **C(**kw), chain=True, susp_rate=SUSP[diff]), seed)
print(r["reason"], round(r["t"]/60, 1), "win", round(r["win_start"]/60, 1) if r["win_start"] else None)
print(" ; ".join(f"{t/60:.1f} {k} {x.replace('RC-','')}" for t, k, x in sorted(r["ev"]) if k not in ("escape",)))
