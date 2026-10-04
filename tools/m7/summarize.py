# M7 기준선 요약: 난이도별 json(runs 행)을 합쳐 승률·길이·종료 경로를 낸다. 사용: python tools/m7/summarize.py <난이도> [태그]
import glob, json, os, sys, statistics as st
d = sys.argv[1]
tag = sys.argv[2] if len(sys.argv) > 2 else ""
base = os.path.expandvars(r"%APPDATA%\Godot\app_userdata\SpaceBattleOfThreeKingdoms")
rows = []
for f in glob.glob(os.path.join(base, f"m7_{d}{tag}_[0-9]*.json")):
    j = json.load(open(f, encoding="utf-8"))
    rows += j["policies"]["none"]["runs"]
rows.sort(key=lambda r: r["seed"])
n = len(rows)
w = sum(1 for r in rows if r["win"]) / n
ts = sorted(r["t"] for r in rows)
reasons = {}
for r in rows:
    reasons[r["reason"]] = reasons.get(r["reason"], 0) + 1
se = (w * (1 - w) / n) ** 0.5
print(f"{d} n={n} 연합승률 {w:.1%} ±{se:.1%} 길이 중앙 {ts[n//2]/60:.1f}분 p10 {ts[n//10]/60:.1f} p90 {ts[9*n//10]/60:.1f} 평균 {st.mean(ts)/60:.1f}분")
print("  종료경로", {k: f"{v/n:.1%}" for k, v in sorted(reasons.items(), key=lambda x: -x[1])})
print("  시계종료", f"{reasons.get('time_limit',0)/n:.1%}", " 조조 확인 접촉 판", f"{sum(1 for r in rows if r['conf_t'][1]>=0)/n:.0%}", "연합", f"{sum(1 for r in rows if r['conf_t'][0]>=0)/n:.0%}")
