# M7 기준선 요약: 난이도별 json(runs 행)을 합쳐 승률·길이·종료 경로를 낸다. 사용: python tools/m7/summarize.py <난이도> [태그] [정책, 기본 none]
import glob, json, os, sys, statistics as st
d = sys.argv[1]
tag = sys.argv[2] if len(sys.argv) > 2 else ""
pol = sys.argv[3] if len(sys.argv) > 3 else "none"
base = os.path.expandvars(r"%APPDATA%\Godot\app_userdata\SpaceBattleOfThreeKingdoms")
rows = []
for f in glob.glob(os.path.join(base, f"m7_{d}{tag}_[0-9]*.json")):
    j = json.load(open(f, encoding="utf-8"))
    rows += j["policies"][pol]["runs"]
rows = sorted({r["seed"]: r for r in rows}.values(), key=lambda r: r["seed"])   # 겹친 묶음은 시드로 중복 제거(결정론이라 같은 판)
n = len(rows)
w = sum(1 for r in rows if r["win"]) / n
ts = sorted(r["t"] for r in rows)
reasons = {}
for r in rows:
    reasons[r["reason"]] = reasons.get(r["reason"], 0) + 1
se = (w * (1 - w) / n) ** 0.5
z = 1.96   # Wilson 95% 구간(0·100% 근처에서도 맞다)
wc = (w + z * z / (2 * n)) / (1 + z * z / n)
wh = z * ((w * (1 - w) + z * z / (4 * n)) / n) ** 0.5 / (1 + z * z / n)
print(f"{d} n={n} 연합승률 {w:.1%} ±{se:.1%} 길이 중앙 {ts[n//2]/60:.1f}분 p10 {ts[n//10]/60:.1f} p90 {ts[9*n//10]/60:.1f} 평균 {st.mean(ts)/60:.1f}분")
print("  종료경로", {k: f"{v/n:.1%}" for k, v in sorted(reasons.items(), key=lambda x: -x[1])})
print("  비용 손실 평균 연합", f"{st.mean(max(0, r.get('ally_cost_loss_bp', 0)) for r in rows)/100:.1f}%", "조조", f"{st.mean(max(0, r.get('foe_cost_loss_bp', 0)) for r in rows)/100:.1f}%", " 95%CI 승률(Wilson)", f"{wc-wh:.1%}~{wc+wh:.1%}")
if "cost0" in rows[0]:
    rs = [r["cost0"][1] / r["cost0"][0] for r in rows]
    print(f"  실제 조조 비용 비율(임무장비 제외) 평균 {st.mean(rs):.3f} 범위 {min(rs):.3f}~{max(rs):.3f}")
print("  시계종료", f"{reasons.get('time_limit',0)/n:.1%}", " 조조 확인 접촉 판", f"{sum(1 for r in rows if r['conf_t'][1]>=0)/n:.0%}", "연합", f"{sum(1 for r in rows if r['conf_t'][0]>=0)/n:.0%}")
# M9: 화공·승계·강습(행에 m9가 있을 때)
m9 = [r.get("m9", {}) for r in rows]
ch = [m.get("chain") for m in m9 if m.get("chain")]
if ch:
    k = len(ch)
    lt = [c for c in ch if c["letter_t"] >= 0]
    ig = [(c, r) for c, r in zip([m.get("chain") for m in m9], rows) if c and c["ignite_t"] >= 0]
    det = sum(1 for c in ch if c["detected"] > 0)
    print(f"  화공: 서신 {len(lt)/k:.0%} 발동 {len(ig)/k:.0%} (위장 중 {sum(1 for c,_ in ig if c['feigned'])/k:.0%}) 간파 {det/k:.0%}"
          f" 번짐 0/1/2 {[sum(1 for c,_ in ig if c['spreads']==i) for i in range(3)]} 위력 평균 {st.mean([c['ignite_power'] for c,_ in ig]) if ig else 0:.3f}")
    cnt = {}
    for c in ch:
        for x in c["counters"]:
            cnt[x] = cnt.get(x, 0) + 1
    if ig:
        rel = [c["ignite_t"] - c["win_start_s"] for c, _ in ig]
        wi = sum(1 for _, r in ig if r["win"]) / len(ig)
        wn = [r for c, r in zip([m.get("chain") for m in m9], rows) if c and c["ignite_t"] < 0]
        print(f"  화공 발동판 연합승률 {wi:.0%} (미발동판 {sum(1 for r in wn if r['win'])/max(1,len(wn)):.0%}, {len(wn)}판) 창 시작 뒤 발동 {st.mean(rel):.0f}초 차단 {cnt}"
              f" 창 시작(절대 시계) 평균 {st.mean([c['win_start_s'] for c in ch if c['win_start_s']>=0]):.0f}초")
cm = [m.get("cmd") for m in m9 if m.get("cmd")]
if cm:
    print("  승계 평균", {x: round(st.mean([c[x] for c in cm]), 2) for x in cm[0]})
sk = [m.get("skills") for m in m9 if "skills" in m]
if sk:
    tot = {}
    for s in sk:
        for k, v in s.items():
            tot[k] = tot.get(k, 0) + v
    print(f"  특기 발동 판당 {sum(tot.values())/len(sk):.1f}회, 기술별 판당", {k: round(v/len(sk), 2) for k, v in sorted(tot.items(), key=lambda x: -x[1])})
asl = [m.get("assault") for m in m9 if m.get("assault")]
if asl:
    print("  강습 [시도, 성공] 합", {x: [sum(a[x][0] for a in asl), sum(a[x][1] for a in asl)] for x in asl[0]})
