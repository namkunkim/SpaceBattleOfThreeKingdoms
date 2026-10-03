import sys, json, statistics as st, multiprocessing as mp
import simd
from simd import *
from final3 import C
RXKW = dict(cao_dx=0, stage_d=280, safe_d=280, chain_army_mul=0.25, chain_mor_mul=0.5, win_range=(540, 600))
def job(a):
    diff, chain, seed, kw, dp, north = a
    simd.DP.clear(); simd.DP.update(dp)
    if north: MS.DIFF[diff]["start_morale_bp"]["northern"] = north
    setup_diff(diff, {})
    Q = dict(BASE, **C(**dict(RXKW, **kw)), chain=chain); Q.setdefault("susp_rate", SUSP[diff])
    r = run(Q, seed)
    return dict(t=r["t"], win=r["winner"] == "cao", fh=r["first_hit"], fc=r["fconf"].get("cao"), fa=r["fconf"].get("alliance"),
                fe=r["fest"].get("cao"), sh=r["shots"], ch=any(k == "chain" for _, k, _ in r["ev"]), sp=any(k == "spread" for _, k, _ in r["ev"]), reason=r["reason"])
def med(xs):
    xs = [x for x in xs if x is not None]; return st.median(xs) / 60 if xs else float("nan")
def table(name, dp, kw={}, diffs=("표준", "상급"), N=40, north=8000, pool=None):
    out = []
    for diff in diffs:
        for chain in (False, True):
            rs = pool.map(job, [(diff, chain, s, kw, dp, north if diff == "표준" else None) for s in range(N)])
            ca = sum(r["sh"]["cao"][0] for r in rs); ce = sum(r["sh"]["cao"][1] for r in rs)
            aa = sum(r["sh"]["alliance"][0] for r in rs); ae = sum(r["sh"]["alliance"][1] for r in rs)
            ncf = sum(r["fc"] is None for r in rs)
            line = (f"{name}|{diff}|{'화공' if chain else '없음'}|len {med(r['t'] for r in rs):4.1f}|cao {100*sum(r['win'] for r in rs)/N:3.0f}%"
                    f"|1hit {med(r['fh'] for r in rs):4.1f}|조조확인 {med(r['fc'] for r in rs):4.1f}(무{ncf})|조조추정 {med(r['fe'] for r in rs):4.1f}|연합확인 {med(r['fa'] for r in rs):4.1f}"
                    f"|추정사격 조 {100*ce/max(ca,1):3.0f}% 연 {100*ae/max(aa,1):3.0f}%|chain {100*sum(r["ch"] for r in rs)/N:3.0f}% spread {100*sum(r["sp"] for r in rs)/N:3.0f}%|{dict(__import__("collections").Counter(r["reason"] for r in rs))}")
            print(line, flush=True); out.append(line)
    return out
if __name__ == "__main__":
    name = sys.argv[1]; dp = json.loads(sys.argv[2]); diffs = tuple(sys.argv[3].split(",")); N = int(sys.argv[4])
    kw = json.loads(sys.argv[5]) if len(sys.argv) > 5 else {}
    with mp.Pool(8) as pool: table(name, dp, kw, diffs, N, pool=pool)
