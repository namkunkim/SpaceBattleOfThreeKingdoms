import sys, json
from sim3 import *
def C(per=60, rel=180, d1=720, **kw):
    CR = {"RC-CAO-SQ-01": rel, "RC-CAO-SQ-03": rel, "RC-CAO-SQ-05": rel, "RC-CAO-SQ-06": rel + 180, "RC-CAO-SQ-07": rel + 180}
    P = dict(period=per, cao_dx=150, release=CR, release_hit={}, support=300, support_factions=("sun_quan",),
             stage=[(0, 240), (d1, 170), (d1 + 360, 100)], xr=True)
    P.update(kw); return P
def line(name, r, d, c):
    return (f"{name}|{d}|{'화공' if c else '없음'}|len {r['len']/60:.1f} (IQR {r['len_q'][0]/60:.1f}-{r['len_q'][1]/60:.1f})|cao {r['win']*100:.0f}%|dp {r['dp']:.1f}|waves {r['waves']:.1f} wgap {r['wgap']:.0f}s|fh {r['fh']/60:.1f}"
            f"|det {r['detected']*100:.0f}% chain {r['chain']*100:.0f}% spread {r['spread']*100:.0f}%|{dict(r['reasons'])}")
if __name__ == "__main__":
    name, diff, N = sys.argv[1], sys.argv[2], int(sys.argv[3])
    kw = json.loads(sys.argv[4]) if len(sys.argv) > 4 else {}
    north = kw.pop("_north", None)
    if north: MS.DIFF[diff]["start_morale_bp"]["northern"] = north
    rows = evaluate(C(**kw), diffs=(diff,), N=N, verbose=False)
    for (d, c), r in rows.items(): print(line(name, r, d, c), flush=True)
